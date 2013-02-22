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
