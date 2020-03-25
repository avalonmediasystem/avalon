# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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
    let(:api_output) do
      { 
        id: 'track-1',
        label: 'quality-high',
        url: 'http://www.test.com/test.mp4.m3u8',
        duration: "6315",
        mime_type:  "video/mp4",
        audio_bitrate: "127716.0",
        audio_codec: "AAC",
        video_bitrate: "1000000.0",
        video_codec: "AVC",
        width: "640",
        height: "480"
      }
    end
    let(:derivative) { described_class.from_output(api_output, false) }
                  
    it "Call from ingest API should populate :url and :hls_url" do
      expect(derivative.location_url).to eq('http://www.test.com/test.mp4.m3u8')
    end
  end

  describe "#destroy" do
    let(:derivative) { FactoryBot.create(:derivative) }
    let(:master_file) { double }
    before do
      allow(derivative).to receive(:master_file).and_return(master_file)
    end

    it "should delete" do
      expect { derivative.destroy }.to change { Derivative.count }.by(-1)
    end

    it "should queue DeleteDerivativeJob" do
      expect(DeleteDerivativeJob).to receive(:perform_later).once.with(derivative.absolute_location)
      derivative.destroy
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
