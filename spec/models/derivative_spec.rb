# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
    let(:http_base)  { Settings.streaming.http_base    }
    let(:root)       { Settings.streaming.content_path }
    let(:location)   { "file://#{root}/c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4" }
    let(:audio_derivative) { Derivative.new(audio_codec: 'AAC').tap { |d| d.absolute_location = location } }
    let(:video_derivative) { Derivative.new(video_codec: 'AVC').tap { |d| d.absolute_location = location } }

    around :each do |example|
      old_value = Avalon::StreamMapper.streaming_server
      begin
        example.run
      ensure
        Avalon::StreamMapper.streaming_server = old_value
      end
    end

    describe "generic" do
      before :each do
        Avalon::StreamMapper.streaming_server = :generic
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

      it "HTTP video" do
        expect(video_derivative.streaming_url(true)).to eq("#{http_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4/playlist.m3u8")
      end

      it "HTTP audio" do
        expect(audio_derivative.streaming_url(true)).to eq("#{http_base}/mp4:c5e0f8b8-3f69-40de-9524-604f03b5f867/8c871d4b-a9a6-4841-8e2a-dd98cf2ee625/content.mp4/playlist.m3u8")
      end
    end
  end

  describe "#download_path" do
    subject { described_class.new }
    before :each do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ENCODE_WORK_DIR").and_return("file://")
      allow(subject).to receive(:hls_url).and_return(hls_url)
    end

    describe "generic" do
      let(:hls_url) { "http://localhost:3000/streams/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4.m3u8" }
      it "provides a file path" do
        allow(Settings.streaming).to receive(:server).and_return(:generic)
        expect(subject.download_path).to eq "file://6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4"
      end
    end

    describe "adobe" do
      let(:hls_url) { "http://localhost:3000/streams/audio-only/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4.m3u8" }
      it "provides a file path" do
        allow(Settings.streaming).to receive(:server).and_return(:adobe)
        expect(subject.download_path).to eq "file://6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4"
      end
    end

    describe "wowza" do
      let(:hls_url) { "http://localhost:3000/streams/mp4:6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4/playlist.m3u8" }
      it "provides a file path" do
        allow(Settings.streaming).to receive(:server).and_return(:wowza)
        expect(subject.download_path).to eq "file://6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4"
      end
    end

    describe "nginx" do
      let(:hls_url) { "http://localhost:3000/streams/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4/index.m3u8" }
      it "provides a file path" do
        allow(Settings.streaming).to receive(:server).and_return(:nginx)
        expect(subject.download_path).to eq "file://6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4"
      end
    end

    describe "s3" do
      let(:hls_url) { "http://localhost:3000/streams/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4.m3u8" }
      before do
        @encoding_backup = Settings.encoding
        Settings.encoding = double("encoding", engine_adapter: 'test', derivative_bucket: 'mybucket')

        # We are using the generic format for hls url in this test, so we should explicitly define the generic streaming server
        allow(Settings.streaming).to receive(:server).and_return(:generic)
      end

      it "provides a s3 path" do
        expect(subject.download_path).to eq "s3://mybucket/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4"
      end

      after do
        Settings.encoding = @encoding_backup
      end
    end
  end
end
