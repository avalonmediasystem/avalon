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

  describe "masterfile" do
    it "should set relationships on self and masterfile" do
      derivative = Derivative.new
      mf = FactoryGirl.build(:master_file)
      mf.save
      derivative.save

      derivative.relationships(:is_derivation_of).size.should == 0
      mf.relationships(:has_derivation).size.should == 0

      derivative.masterfile = mf

      derivative.relationships(:is_derivation_of).size.should == 1
#      mf.relationships(:has_derivation).size.should == 1
      derivative.relationships(:is_derivation_of).first.should eq "info:fedora/#{mf.pid}"
#      mf.relationships(:has_derivation).first.should eq "info:fedora/#{derivation.pid}"

      derivative.relationships_are_dirty.should be true
#      mf.relationships_are_dirty.should be true
    end
  end

  describe "destroy" do
    let!(:derivative) {FactoryGirl.create(:derivative)}

    it "should delete and retract files" do
      expect{derivative.destroy}.to change{Derivative.count}.by(-1)
    end 

    it "should not throw error when location_url is missing" do
      derivative.location_url = nil
      derivative.destroy
      Derivative.all.count.should == 0
    end

    it "should not throw error when workflow doesn't exist in Matterhorn" do
      derivative.destroy
      Derivative.all.count.should == 0
    end

    it "should delete even if retraction fails (VOV-1356)" do
      Rubyhorn.stub_chain(:client,:delete_track).and_raise("Stream not found error")
      Rubyhorn.stub_chain(:client,:delete_hls_track).and_raise("Stream not found error")

      expect{derivative.destroy}.to change{Derivative.count}.by(-1)
    end 
  end

  describe "streaming" do

    before :each do
      @d = Derivative.new
      @rtmp_base = Avalon::Configuration.lookup('streaming.rtmp_base')
      @http_base = Avalon::Configuration.lookup('streaming.http_base')
      @d.location_url = "#{@rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4"
    end

    describe "generic" do
      before :each do
        Derivative.url_handler = UrlHandler::Generic
      end

      it "should properly create an RTMP video streaming URL" do
        @d.encoding.video = 'true'
        @d.streaming_url(false).should == "#{@rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "should properly create an RTMP audio streaming URL" do
        @d.encoding.audio = 'true'
        @d.streaming_url(false).should == "#{@rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "should properly create an HTTP video streaming URL" do
        @d.encoding.video = 'true'
        @d.streaming_url(true).should == "#{@http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end

      it "should properly create an HTTP audio streaming URL" do
        @d.encoding.audio = 'true'
        @d.streaming_url(true).should == "#{@http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end
    end

    describe "adobe" do
      before :each do
        Derivative.url_handler = UrlHandler::Adobe
      end

      it "should properly create an RTMP video streaming URL" do
        @d.encoding.video = 'true'
        @d.streaming_url(false).should == "#{@rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "should properly create an RTMP audio streaming URL" do
        @d.encoding.audio = 'true'
        @d.streaming_url(false).should == "#{@rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "should properly create an HTTP video streaming URL" do
        @d.encoding.video = 'true'
        @d.streaming_url(true).should == "#{@http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end

      it "should properly create an HTTP audio streaming URL" do
        @d.encoding.audio = 'true'
        @d.streaming_url(true).should == "#{@http_base}/audio-only/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end
    end
  end
end
