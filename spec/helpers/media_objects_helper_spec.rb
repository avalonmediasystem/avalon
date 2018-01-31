# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

describe MediaObjectsHelper do
  describe "#current_quality" do
    before(:all) do
      @streaming_config = Settings.streaming
      Settings.streaming.default_quality = "low"
    end
    after(:all) do
      Settings.streaming = @streaming_config
    end
    let(:stream_info) {{stream_flash: [{quality: 'high'}, {quality: 'medium'}, {quality: 'low'}], stream_hls: [{quality: 'high'}, {quality: 'medium'}, {quality: 'low'}]}}
    let(:skip_transcoded_stream_info) {{stream_flash: [{quality: 'high'}], stream_hls: [{quality: 'high'}]}}

    it "should return sticky session setting if available" do
      session[:quality] = 'medium'
      expect(helper.current_quality(stream_info)).to eq 'medium'
    end
    it "should return the default setting if available and sticky session setting is not available" do
      expect(helper.current_quality(stream_info)).to eq 'low'
    end
    it "should return the first available quality if the default or sticky session setting are not available" do
      expect(helper.current_quality(skip_transcoded_stream_info)).to eq 'high'
    end
  end

  describe "#parse_hour_min_sec" do
    it "returns a milliseconds representation" do
      expect(helper.parse_hour_min_sec("00:00:01")).to eq 1.0
      expect(helper.parse_hour_min_sec("00:00:01.259")).to eq 1.259
      expect(helper.parse_hour_min_sec("00:01:01.259")).to eq 61.259
      expect(helper.parse_hour_min_sec("00:10:11.259")).to eq 611.259
      expect(helper.parse_hour_min_sec("1:10:11.259")).to eq 4211.259
      expect(helper.parse_hour_min_sec("10:11.259")).to eq 611.259
      expect(helper.parse_hour_min_sec("11.259")).to eq 11.259
      expect(helper.parse_hour_min_sec("xx:11.259")).to eq 11.259
      expect(helper.parse_hour_min_sec("hello")).to eq 0.0
    end
  end

  describe "#get_duration_from_fragment" do
    it "returns a human readable duration" do
      expect(helper.get_duration_from_fragment(0, 100)).to eq "01:40"
      expect(helper.get_duration_from_fragment(100, 200)).to eq "01:40"
      expect(helper.get_duration_from_fragment(100, 20000)).to eq "5:31:40"
    end
  end
end
