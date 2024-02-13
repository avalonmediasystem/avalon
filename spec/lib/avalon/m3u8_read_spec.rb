# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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
require 'avalon/m3u8_reader'

describe Avalon::M3U8Reader do
  let(:m3u_filename)  { File.expand_path('../../../fixtures/The_Fox.mp4.m3u',__FILE__) }
  let(:m3u)       { Avalon::M3U8Reader.read(m3u_filename) }
  let(:framespec) { m3u.at(127000) }

  context 'with a filepath' do
    it "should know how many files it has" do
      expect(m3u.files.length).to eq(23)
    end

    it "should know its duration" do
      expect(m3u.duration.round(2)).to eq(225.14)
    end

    it "should be able to locate a frame" do
      expect(framespec[:location]).to match(%r{/The_Fox.mp4-012.ts$})
      expect(framespec[:filename]).to eq('The_Fox.mp4-012.ts')
      expect(framespec[:offset].round(2)).to eq(6818.91)
    end
  end

  context 'with a url' do
    let(:m3u_url) { Rails.application.routes.url_helpers.hls_manifest_master_file_url(id: 1, quality: "auto") }
    let(:m3u) { Avalon::M3U8Reader.read(m3u_url) }

    before do
      stub_request(:get, m3u_url).to_return(body: File.read(m3u_filename))
    end

    it "should know how many files it has" do
      expect(m3u.files.length).to eq(23)
    end

    it "should know its duration" do
      expect(m3u.duration.round(2)).to eq(225.14)
    end

    it "should be able to locate a frame" do
      expect(framespec[:location]).to match(%r{/The_Fox.mp4-012.ts$})
      expect(framespec[:filename]).to eq('The_Fox.mp4-012.ts')
      expect(framespec[:offset].round(2)).to eq(6818.91)
    end
  end

  context 'with a file' do
    let(:m3u_file) { File.open(m3u_filename) }
    let(:m3u) { Avalon::M3U8Reader.read(m3u_file) }

    it "should know how many files it has" do
      expect(m3u.files.length).to eq(23)
    end

    it "should know its duration" do
      expect(m3u.duration.round(2)).to eq(225.14)
    end

    it "should be able to locate a frame" do
      expect(framespec[:location]).to match(%r{/The_Fox.mp4-012.ts$})
      expect(framespec[:filename]).to eq('The_Fox.mp4-012.ts')
      expect(framespec[:offset].round(2)).to eq(6818.91)
    end
  end

  context 'with a string' do
    let(:m3u_file_contents) { File.read(m3u_filename) }
    let(:m3u) { Avalon::M3U8Reader.read(m3u_file_contents) }

    it "should know how many files it has" do
      expect(m3u.files.length).to eq(23)
    end

    it "should know its duration" do
      expect(m3u.duration.round(2)).to eq(225.14)
    end

    it "should be able to locate a frame" do
      expect(framespec[:location]).to match(%r{/The_Fox.mp4-012.ts$})
      expect(framespec[:filename]).to eq('The_Fox.mp4-012.ts')
      expect(framespec[:offset].round(2)).to eq(6818.91)
    end
  end
end
