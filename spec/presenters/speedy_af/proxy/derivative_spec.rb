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

require 'rails_helper'

describe SpeedyAF::Proxy::Derivative do
  let(:derivative) { FactoryBot.create(:derivative) }
  subject(:presenter) { described_class.find(derivative.id) }

  describe 'attributes' do
    let(:derivative) { FactoryBot.create(:derivative, mime_type: 'video/mp4') }

    it 'returns all attributes' do
      expect(presenter.location_url).to be_present #also stored as stream_path_ssi?
      expect(presenter.hls_url).to be_present
      expect(presenter.duration).to be_present
      expect(presenter.track_id).to be_present
      expect(presenter.hls_track_id).to be_present
      expect(presenter.managed).not_to be_nil
      expect(presenter.derivativeFile).to be_present
      expect(presenter.quality).to be_present
      expect(presenter.mime_type).to be_present
      expect(presenter.audio_bitrate).to be_present
      expect(presenter.audio_codec).to be_present
      expect(presenter.video_bitrate).to be_present
      expect(presenter.video_codec).to be_present
      expect(presenter.resolution).to be_present
    end
  end

  describe "#defaults" do
    before(:each) do
      derivative.video_codec = nil
      derivative.video_bitrate = nil
      derivative.mime_type = nil
      derivative.save
    end

    it "sets video_bitrate to nil" do
      expect(subject.inspect).to include("video_bitrate")
      expect(subject.video_bitrate).to be_nil
    end

    it "sets video_codec to nil" do
      expect(subject.inspect).to include("video_codec")
      expect(subject.video_codec).to be_nil
    end

    it "sets mime_type to nil" do
      expect(subject.inspect).to include("mime_type")
      expect(subject.mime_type).to be_nil
    end
  end
end
