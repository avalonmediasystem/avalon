# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

require 'rails_helper'
require 'avalon/elastic_transcoder'

describe Avalon::ElasticTranscoder do
  let(:et){ Avalon::ElasticTranscoder.instance }

  describe "#find_preset" do
    it 'calls #find_preset_by_name' do
      expect(et).to receive(:find_preset_by_name).with("avalon-video-low-mp4")
      et.find_preset("mp4", :video, :low)
    end
  end

  describe "#find_preset_by_name" do
    before do
      et.etclient.stub_responses(:list_presets, {
        presets: [{ name: "avalon-video-low-mp4" }]
      })
    end

    it 'returns an existing preset' do
      expect(et.find_preset_by_name("avalon-video-low-mp4")).to be_an(Aws::ElasticTranscoder::Types::Preset)
    end

    it 'returns nil if a preset cannot be found' do
      expect(et.find_preset_by_name("example-video-low-mp4")).to be_nil
    end

    it 'caches result' do
      Rails.cache.clear
      et.find_preset_by_name("avalon-video-low-mp4")
      expect(et.etclient).not_to receive(:list_presets)
      et.find_preset_by_name("avalon-video-low-mp4")
    end
  end

  describe "#create_preset" do
    it 'returns a preset' do
      expect(et.create_preset({ name: "test", container: "mp4" }).preset).to be_an(Aws::ElasticTranscoder::Types::Preset)
    end
  end

  describe "#read_templates" do
    it 'returns an array' do
      expect(et.read_templates(Rails.root.join('config', 'encoding_presets.yml')).length).to eq(12)
    end
  end
end
