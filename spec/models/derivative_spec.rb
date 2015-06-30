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

describe Derivative do

  describe "#destroy" do
    let!(:derivative) {FactoryGirl.create(:derivative)}

    it "should delete and retract files" do
      encode = ActiveEncode::Base.new(nil)
      expect(ActiveEncode::Base).to receive(:find).and_return(encode)
      expect(encode).to receive(:remove_output!).twice.and_return({})
      expect{derivative.destroy}.to change{Derivative.count}.by(-1)
    end 

    it "should not throw error when encode doesn't exist anymore" do
      expect(ActiveEncode::Base).to receive(:find).and_return nil
      expect{derivative.destroy}.to change{Derivative.count}.by(-1)
    end

    it "should delete even if retraction fails" do
      encode = ActiveEncode::Base.new(nil)
      expect(ActiveEncode::Base).to receive(:find).and_return(encode)
      expect(encode).to receive(:remove_output!).and_raise Exception
      expect{derivative.destroy}.to change{Derivative.count}.by(-1)
    end 
  end

  describe "streaming" do
    let(:rtmp_base)  { Avalon::Configuration.lookup('streaming.rtmp_base')    }
    let(:http_base)  { Avalon::Configuration.lookup('streaming.http_base')    }
    let(:root)       { Avalon::Configuration.lookup('streaming.content_path') }
    let(:location)   { "file://#{root}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4" }
    let(:derivative) { Derivative.new }

    describe "generic" do
      before :each do
        Avalon::StreamMapper.streaming_server = :generic
      end

      it "RTMP video" do
        derivative.encoding.video = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(false).should == "#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "RTMP audio" do
        derivative.encoding.audio = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(false).should == "#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "HTTP video" do
        derivative.encoding.video = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(true).should == "#{http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end

      it "HTTP audio" do
        derivative.encoding.audio = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(true).should == "#{http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end
    end

    describe "adobe" do
      before :each do
        Avalon::StreamMapper.streaming_server = :adobe
      end

      it "RTMP video" do
        derivative.encoding.video = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(false).should == "#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "RTMP audio" do
        derivative.encoding.audio = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(false).should == "#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "HTTP video" do
        derivative.encoding.video = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(true).should == "#{http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end

      it "HTTP audio" do
        derivative.encoding.audio = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(true).should == "#{http_base}/audio-only/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end
    end

    describe "wowza" do
      before :each do
        Avalon::StreamMapper.streaming_server = :wowza
      end

      it "RTMP video" do
        derivative.encoding.video = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(false).should == "#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "RTMP audio" do
        derivative.encoding.audio = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(false).should == "#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "HTTP video" do
        derivative.encoding.video = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(true).should == "#{http_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4/playlist.m3u8"
      end

      it "HTTP audio" do
        derivative.encoding.audio = 'true'
        derivative.absolute_location = location
        derivative.streaming_url(true).should == "#{http_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4/playlist.m3u8"
      end
    end
  end
end
