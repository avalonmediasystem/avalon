# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'spec_helper'

describe MediaObjectsHelper do
  describe "#current_quality" do
    before(:each) do
      allow(Avalon::Configuration).to receive('[]').with("streaming").and_return({"default_quality" => "low"})
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
end
