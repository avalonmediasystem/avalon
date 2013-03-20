require 'spec_helper'

describe Derivative do
  describe "masterfile" do
    it "should set relationships on self and masterfile" do
      derivative = Derivative.new
      mf = MasterFile.new
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

      File.open(Avalon::Configuration['matterhorn']['cleanup_log'], "w+") { |f| f = "" }
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

    after :each do 
    end
  end

  describe "streaming" do

    before :each do
      @d = Derivative.new
      @d.location_url = "rtmp://localhost/avalon/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4"
    end

    describe "generic" do
      before :each do
        Derivative.url_handler = UrlHandler::Generic
      end

      it "should properly create an RTMP video streaming URL" do
        @d.encoding.video = 'true'
        @d.streaming_url(false).should == "rtmp://localhost/avalon/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "should properly create an RTMP audio streaming URL" do
        @d.encoding.audio = 'true'
        @d.streaming_url(false).should == "rtmp://localhost/avalon/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "should properly create an HTTP video streaming URL" do
        @d.encoding.video = 'true'
        @d.streaming_url(true).should == "http://localhost:3000/streams/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end

      it "should properly create an HTTP audio streaming URL" do
        @d.encoding.audio = 'true'
        @d.streaming_url(true).should == "http://localhost:3000/streams/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end
    end

    describe "adobe" do
      before :each do
        Derivative.url_handler = UrlHandler::Adobe
      end

      it "should properly create an RTMP video streaming URL" do
        @d.encoding.video = 'true'
        @d.streaming_url(false).should == "rtmp://localhost/avalon/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "should properly create an RTMP audio streaming URL" do
        @d.encoding.audio = 'true'
        @d.streaming_url(false).should == "rtmp://localhost/avalon/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content"
      end

      it "should properly create an HTTP video streaming URL" do
        @d.encoding.video = 'true'
        @d.streaming_url(true).should == "http://localhost:3000/streams/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end

      it "should properly create an HTTP audio streaming URL" do
        @d.encoding.audio = 'true'
        @d.streaming_url(true).should == "http://localhost:3000/streams/audio-only/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8"
      end
    end
  end
end
