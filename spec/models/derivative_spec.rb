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

describe Derivative do

  describe "#from_output" do
    let!(:api_output){[{ label: 'quality-high',
                    id: 'track-1',
                    url: 'rtmp://www.test.com/test.mp4',
                    hls_url: 'http://www.test.com/test.mp4.m3u8',
                    duration: "6315",
                    mime_type:  "video/mp4",
                    audio_bitrate: "127716.0",
                    audio_codec: "AAC",
                    video_bitrate: "1000000.0",
                    video_codec: "AVC",
                    width: "640",
                    height: "480" }]}
    it "Call from ingest API should populate :url and :hls_url" do
      d = Derivative.from_output(api_output,false)
      expect(d.location_url).to eq('rtmp://www.test.com/test.mp4')
      expect(d.hls_url).to eq('http://www.test.com/test.mp4.m3u8')
    end
  end

  describe "#destroy" do
    let(:derivative) {FactoryGirl.create(:derivative)}
    let(:master_file) { double }
    before do
      allow(derivative).to receive(:master_file).and_return(master_file)
      allow(master_file).to receive(:encoder_class).and_return(ActiveEncode::Base)
      allow(master_file).to receive(:workflow_id).and_return(Faker::Number.digit)
    end

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
      expect(encode).to receive(:remove_output!).and_raise StandardError
      expect{derivative.destroy}.to change{Derivative.count}.by(-1)
    end
  end

  describe "streaming" do
    let(:rtmp_base)  { Settings.streaming.rtmp_base    }
    let(:http_base)  { Settings.streaming.http_base    }
    let(:root)       { Settings.streaming.content_path }
    let(:location)   { "file://#{root}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4" }
    let(:audio_derivative) { Derivative.new(audio_codec: 'AAC').tap { |d| d.absolute_location = location } }
    let(:video_derivative) { Derivative.new(video_codec: 'AVC').tap { |d| d.absolute_location = location } }

    describe "generic" do
      before :each do
        Avalon::StreamMapper.streaming_server = :generic
      end

      it "RTMP video" do
        expect(video_derivative.streaming_url(false)).to eq("#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content")
      end

      it "RTMP audio" do
        expect(audio_derivative.streaming_url(false)).to eq("#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content")
      end

      it "HTTP video" do
        expect(video_derivative.streaming_url(true)).to eq("#{http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8")
      end

      it "HTTP audio" do
        expect(audio_derivative.streaming_url(true)).to eq("#{http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8")
      end
    end

    describe "adobe" do
      before :each do
        Avalon::StreamMapper.streaming_server = :adobe
      end

      it "RTMP video" do
        expect(video_derivative.streaming_url(false)).to eq("#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content")
      end

      it "RTMP audio" do
        expect(audio_derivative.streaming_url(false)).to eq("#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content")
      end

      it "HTTP video" do
        expect(video_derivative.streaming_url(true)).to eq("#{http_base}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8")
      end

      it "HTTP audio" do
        expect(audio_derivative.streaming_url(true)).to eq("#{http_base}/audio-only/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4.m3u8")
      end
    end

    describe "wowza" do
      before :each do
        Avalon::StreamMapper.streaming_server = :wowza
      end

      it "RTMP video" do
        expect(video_derivative.streaming_url(false)).to eq("#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content")
      end

      it "RTMP audio" do
        expect(audio_derivative.streaming_url(false)).to eq("#{rtmp_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content")
      end

      it "HTTP video" do
        expect(video_derivative.streaming_url(true)).to eq("#{http_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4/playlist.m3u8")
      end

      it "HTTP audio" do
        expect(audio_derivative.streaming_url(true)).to eq("#{http_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4/playlist.m3u8")
      end
    end
  end
end
