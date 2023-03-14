# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

describe WaveformService, type: :service do
  let(:service) { WaveformService.new }

  describe "get_waveform_json" do
    let(:wav_path) { File.join(Rails.root, "spec/fixtures/meow.wav") }

    it "should return waveform json from file" do
      allow(service).to receive(:get_wave_io).and_return(open(wav_path))
      json = JSON.parse(service.get_waveform_json(Addressable::URI.parse("file:///path/to/video.mp4")))
      target_json = JSON.parse(File.read("spec/fixtures/meow.json"))

      expect(json).to eq(target_json)
    end

    context "s3 file" do
      let(:uri) { Addressable::URI.parse("s3://path/to/video.mp4") }
      let(:tmpfile) { Tempfile.new }

      before do
        allow(Tempfile).to receive(:new).and_return tmpfile
      end

      it "should clean up Tempfile" do
        service.get_waveform_json(uri)
        expect(tmpfile.path).to eq nil
      end
    end

    context 'when uri parameter is blank' do
      it 'returns nil' do
        expect(service.get_waveform_json(nil)).to eq nil
      end
    end
  end

  describe "get empty waveform" do
    let(:service) { WaveformService.new }
    let(:master_file) { FactoryBot.create(:master_file, :with_derivative, :with_structure) }

    it "should return empty waveform json" do
      waveform = service.empty_waveform(master_file)
      expect(waveform).to be_kind_of IndexedFile
      expect(waveform.original_name).to eq 'empty_waveform.json'
    end
  end

  describe "get_wave_io" do
    before do
      allow(IO).to receive(:popen).and_return(nil)
    end

    context "http file" do
      let(:uri) { "http://domain/to/video.mp4" }
      let(:cmd) {"#{Settings.ffmpeg.path} -headers $'Referer: http://test.host/\r\n' -rw_timeout 3600000000 -i '#{uri}' -f wav -ar 44100 - 2> /dev/null"}

      it "should call ffmpeg with headers" do
        service.send(:get_wave_io, uri)
        expect(IO).to have_received(:popen).with(cmd)
      end
    end

    context "local file" do
      let(:uri) { "file:///path/to/video.mp4" }
      let(:cmd) {"#{Settings.ffmpeg.path}  -rw_timeout 3600000000 -i '#{uri}' -f wav -ar 44100 - 2> /dev/null"}

      it "should call ffmpeg without headers" do
        service.send(:get_wave_io, uri)
        expect(IO).to have_received(:popen).with(cmd)
      end

      context 'with spaces in filename' do
        let(:uri) { 'file:///path/to/special%20video%20file.mp4' }
        let(:unencoded_uri) { 'file:///path/to/special video file.mp4' }
        let(:cmd) {"#{Settings.ffmpeg.path}  -rw_timeout 3600000000 -i '#{unencoded_uri}' -f wav -ar 44100 - 2> /dev/null"}

        it "should call ffmpeg without url encoding" do
          service.send(:get_wave_io, uri)
          expect(IO).to have_received(:popen).with(cmd)
        end
      end
    end
  end
end
