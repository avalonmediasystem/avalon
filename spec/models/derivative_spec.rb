# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

  describe "#set_absolute_location" do
    let(:derivative){ FactoryGirl.build(:derivative)}
    it 'sets absolute location' do
      (application, prefix, media_id, stream_id, filename, extension) = derivative.parse_location
      derivative.absolute_location.should == "/files/something/#{parts[:media_id]}/#{parts[:stream_id]}/#{parts[:filename]}"
    end
    it 'does not set absolute location when stream_base_path is nil' do
      derivative.absolute_location.should be_nil
    end
  end

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

  describe "deleting" do
    before :each do 
      @derivative = Derivative.new
      @derivative.track_id = "track-1"
      @derivative.hls_track_id = "track-2"

      mf = MasterFile.new
      mf.workflow_id = "1"
      @derivative.masterfile = mf

      @derivative.save

      File.open(Avalon::Configuration['matterhorn']['cleanup_log'], "w+") {}
    end

    it "should delete and start retraction jobs" do
      pid = @derivative.pid

      job_urls = ["http://test.com/retract_rtmp.xml", "http://test.com/retract_hls.xml"]
      Rubyhorn.stub_chain(:client,:delete_track).and_return(job_urls[0])
      Rubyhorn.stub_chain(:client,:delete_hls_track).and_return(job_urls[1])

      prev_count = Derivative.all.count
      @derivative.delete 

      Derivative.all.count.should == prev_count - 1
      log_count = 0
      file = File.new(Avalon::Configuration['matterhorn']['cleanup_log'])
      file.each { |line| log_count += 1 if line.start_with?(job_urls[0]) || line.start_with?(job_urls[1]) }
      log_count.should == 2
    end 

    it "should delete even if retraction fails (VOV-1356)" do
      pending "Do not test until VOV-1356 is fixed"
      pid = @derivative.pid

      Rubyhorn.stub_chain(:client,:delete_track).and_raise("Stream not found error")
      Rubyhorn.stub_chain(:client,:delete_hls_track).and_raise("Stream not found error")

      expect { @derivative.delete }.to change(Derivative.all.count).by(-1)
    end 
  end

  describe "streaming" do

    before :each do
      @d = Derivative.new
      @rtmp_base = Avalon::Configuration['streaming']["rtmp_base"]
      @http_base = Avalon::Configuration['streaming']["http_base"]
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
