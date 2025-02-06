# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

# frozen_string_literal: true
require 'rails_helper'

describe WatchedEncode do
  include ActiveJob::TestHelper

  let(:master_file) { FactoryBot.create(:master_file, :not_processing) }
  let(:encode) { described_class.new("sample.mp4", master_file_id: master_file.id) }
  let(:running_encode) do
    encode.clone.tap do |e|
      e.id = SecureRandom.uuid
      e.state = :running
      e.created_at = Time.zone.now
      e.updated_at = Time.zone.now
    end
  end
  let(:completed_encode) do
    running_encode.clone.tap do |e| 
      e.state = :completed
      output = double(url: 'file://' + Rails.root.join('spec', 'fixtures', fixture_file).to_s)
      allow(output).to receive(:url=)
      allow(output).to receive(:format)
      e.output = [output]
    end
  end
  let(:fixture_file) { 'videoshort.mp4' }

  before do
    allow(MasterFile).to receive(:find).with(master_file.id).and_return(master_file)
    allow(master_file).to receive(:update_progress_on_success!)
  end

  describe 'create' do
    before do
      # Return a completed encode so the polling job doesn't run forever.
      allow(described_class.engine_adapter).to receive(:create).and_return(completed_encode)
    end

    it 'stores the encode id on the master file' do
      encode.create!
      expect(master_file.reload.workflow_id).to eq encode.id.to_s
    end

    it 'creates an encode record' do
      encode.create!
      encode_record = ActiveEncode::EncodeRecord.last
      expect(encode_record.title).to eq 'sample.mp4'
      expect(encode_record.display_title).to eq 'sample.mp4'
    end
  end

  describe 'polling update' do
    around(:example) do |example|
      # In Rails 5.1+ this can be restricted to allow listed jobs to be performed
      perform_enqueued_jobs { example.run }
    end

    before do
      # Return a completed encode so the polling job doesn't run forever.
      allow(described_class.engine_adapter).to receive(:create).and_return(running_encode)
      allow(described_class.engine_adapter).to receive(:find).and_return(completed_encode)
    end

    it 'stores the encode id on the master file' do
      encode.create!
      expect(master_file).to have_received(:update_progress_on_success!)
    end

    context 'using Minio and ffmpeg adapter' do
      let(:encode) { described_class.new(minio_url, master_file_id: master_file.id) }
      let(:minio_url) { "http://minio:9000/masterfiles/uploads/c0b216da-bb53-4afd-8d4c-c4761a78e230/#{fixture_file}?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=minio%2F20231101%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231101T202236Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=982ffe02232c053ee38f470f4ec4844c3302ceb35afd4f3f8564731c51b5a044" }

      before do
        Settings.minio = double("minio", endpoint: "http://minio:9000", public_host: "http://domain:9000")
        allow(Settings).to receive(:encoding).and_return(double(engine_adapter: "ffmpeg", derivative_bucket: "derivs"))
        allow(File).to receive(:delete)
      end

      it 'uploads to Minio' do
        encode.create!
        expect(master_file).to have_received(:update_progress_on_success!)
      end

      it 'creates an encode record' do
        encode.create!
        encode_record = ActiveEncode::EncodeRecord.last
        expect(encode_record.title).to eq fixture_file
        expect(encode_record.display_title).to eq fixture_file
      end

      context 'with embedded captions' do
        let(:caption_file) { 'captions.vtt' }
        let(:sup_file) { double(url: 'file://supplemental_files' + Rails.root.join('spec', 'fixtures', caption_file).to_s, format: "vtt", label: "Test Caption", language: nil) }
        let(:completed_encode) do
          running_encode.clone.tap do |e| 
            e.state = :completed
            output = double(url: 'file://' + Rails.root.join('spec', 'fixtures', fixture_file).to_s)
            allow(output).to receive(:url=)
            allow(output).to receive(:format)
            allow(sup_file).to receive(:url=)
            allow(sup_file).to receive(:id=)
            e.output = [output, sup_file]
          end
        end

        before do
          allow_any_instance_of(ActiveStorage::Blob).to receive(:url).and_return("https://example.com")
        end

        it 'creates a SupplementalFile and attaches caption file' do
          expect { encode.create! }.to change { SupplementalFile.all.count }.by(1)
          supplemental_file = SupplementalFile.last
          expect(supplemental_file.file).to be_attached
          expect(supplemental_file.file.byte_size).to be_positive
          expect(supplemental_file.label).to eq "Test Caption"
          expect(master_file).to have_received(:update_progress_on_success!)
        end

        it 'creates an encode record' do
          encode.create!
          encode_record = ActiveEncode::EncodeRecord.last
          expect(encode_record.title).to eq fixture_file
          expect(encode_record.display_title).to eq fixture_file
        end

        context "language processing" do
          it "accepts two letter codes" do
            allow(sup_file).to receive(:language).and_return("es")
            encode.create!
            supplemental_file = SupplementalFile.last
            expect(supplemental_file.language).to eq "spa"
          end

          it "accepts three letter codes" do
            allow(sup_file).to receive(:language).and_return("fre")
            encode.create!
            supplemental_file = SupplementalFile.last
            expect(supplemental_file.language).to eq "fre"
          end

          it "defaults to English when there is an issue with the language code" do
            allow(sup_file).to receive(:language).and_return("error")
            encode.create!
            supplemental_file = SupplementalFile.last
            expect(supplemental_file.language).to eq "eng"
          end
        end 
      end

      after do
        Settings.minio = nil
      end

      context 'with filename with spaces' do
        let(:fixture_file) { 'video short.mp4' }

        it 'uploads to Minio' do
          encode.create!
          expect(master_file).to have_received(:update_progress_on_success!)
        end

        it 'creates an encode record' do
          encode.create!
          encode_record = ActiveEncode::EncodeRecord.last
          expect(encode_record.title).to eq fixture_file
          expect(encode_record.display_title).to eq fixture_file
        end
      end

      context 'with filename with escaped spaces' do
        let(:fixture_file) { 'short%20video.mp4' }

        it 'uploads to Minio' do
          encode.create!
          expect(master_file).to have_received(:update_progress_on_success!)
        end

        it 'creates an encode record' do
          encode.create!
          encode_record = ActiveEncode::EncodeRecord.last
          expect(encode_record.title).to eq fixture_file
          expect(encode_record.display_title).to eq fixture_file
        end
      end
    end
  end
end
