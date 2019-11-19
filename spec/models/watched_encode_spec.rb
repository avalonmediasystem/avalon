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
      output = double(url: 'file://' + Rails.root.join('spec', 'fixtures', 'videoshort.mp4').to_s)
      allow(output).to receive(:url=)
      e.output = [output]
    end
  end

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
  end

  describe 'polling update' do
    around(:example) do |example|
      # In Rails 5.1+ this can be restricted to whitelist jobs allowed to be performed
      perform_enqueued_jobs { example.run }
    end

    before do
      # Return a completed encode so the polling job doesn't run forever.
      allow(described_class.engine_adapter).to receive(:create).and_return(running_encode)
      allow(described_class.engine_adapter).to receive(:find).and_return(completed_encode)
      # allow(master_file).to receive(:update_progress_on_success!)
    end

    it 'stores the encode id on the master file' do
      encode.create!
      expect(master_file).to have_received(:update_progress_on_success!)
    end

    context 'using Minio and ffmpeg adapter' do
      before do
        Settings.minio = double("minio", endpoint: "http://minio:9000", public_host: "http://domain:9000")
        allow(Settings).to receive(:encoding).and_return(double(engine_adapter: "ffmpeg", derivative_bucket: "derivs"))
        allow(File).to receive(:delete)
      end

      it 'uploads to Minio' do
        encode.create!
      end

      after do
        Settings.minio = nil
      end
    end
  end
end