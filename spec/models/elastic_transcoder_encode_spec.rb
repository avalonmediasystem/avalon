# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

describe ElasticTranscoderEncode do
  let(:master_file) { FactoryBot.create(:master_file) }
  let(:encode) { described_class.new("sample.mp4", master_file_id: master_file.id, preset: preset) }
  let(:completed_encode) do
    e = described_class.new("sample.mp4")
    e.id = SecureRandom.uuid
    e.state = :completed
    e.created_at = Time.zone.now
    e.updated_at = Time.zone.now
    e
  end
  let(:et_preset) { double() }

  before do
    # Return a completed encode so the polling job doesn't run forever.
    allow(described_class.engine_adapter).to receive(:create).and_return(completed_encode)
    allow(MasterFile).to receive(:find).with(master_file.id).and_return(master_file)
    allow(Avalon::ElasticTranscoder.instance).to receive(:find_preset).and_return(et_preset)
    allow(et_preset).to receive(:id).and_return('preset-id')
  end

  describe 'create' do
    context 'with audio' do
      let(:preset) { 'fullaudio' }

      it 'sets the outputs' do
        encode.create!
        encode_record = ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s)
        create_outputs = JSON.parse(encode_record.create_options)["outputs"]
        expect(create_outputs.size).to eq 2
        expect(create_outputs).to include(hash_including("preset_id", "key" => 'quality-high/sample.mp4'), hash_including("preset_id", "key" => 'quality-medium/sample.mp4'))
      end
    end

    context 'with video' do
      let(:preset) { 'avalon' }

      it 'sets the outputs' do
        encode.create!
        encode_record = ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s)
        create_outputs = JSON.parse(encode_record.create_options)["outputs"]
        expect(create_outputs.size).to eq 3
        expect(create_outputs).to include(hash_including("preset_id", "key" => 'quality-high/sample.mp4'), hash_including("preset_id", "key" => 'quality-medium/sample.mp4'), hash_including("preset_id", "key" => 'quality-low/sample.mp4'))
      end
    end

    context 'with unknown media' do
      let(:preset) { nil }

      it 'does not set the outputs' do
        encode.create!
        encode_record = ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s)
        create_outputs = JSON.parse(encode_record.create_options)["outputs"]
        expect(create_outputs).to be_empty
      end
    end
  end
end
