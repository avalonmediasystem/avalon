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

describe WaveformJob do
  let(:job) { WaveformJob.new }
  let(:master_file) { FactoryBot.create(:master_file_with_media_object_and_derivative) }
  let(:waveform_json) { File.read('spec/fixtures/waveform.json') }
  let(:service) { instance_double("WaveformService") }

  describe "perform" do
    before do
      allow(service).to receive(:get_waveform_json).and_return(waveform_json)
      allow(WaveformService).to receive(:new).and_return(service)
    end

    it 'calls the waveform service and stores the compressed result' do
      job.perform(master_file.id)
      master_file.reload
      expect(master_file.waveform.mime_type).to eq 'application/zlib'
      expect(Zlib::Inflate.inflate(master_file.waveform.content)).to eq waveform_json
    end

    it 'calls after_processing' do
      allow(MasterFile).to receive(:find).with(master_file.id).and_return(master_file)
      expect(master_file).to receive(:run_hook).with(:after_processing)
      job.perform(master_file.id)
    end

    context 'when on disk' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(master_file.file_location).and_return(true)
      end

      it 'calls the waveform service with the file location' do
        job.perform(master_file.id)
        expect(service).to have_received(:get_waveform_json).with(master_file.file_location)
      end
    end

    context 'when not on disk' do
      let(:secure_hls_url) { "https://path/to/mp4:video.mp4/playlist.m3u8?token=abc" }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(master_file.file_location).and_return(false)
        allow(SecurityHandler).to receive(:secure_url).and_return(secure_hls_url)
      end

      it 'calls the waveform service with the playlist url' do
        job.perform(master_file.id)
        expect(service).to have_received(:get_waveform_json).with(secure_hls_url)
      end
    end

    context 'when master file already has a waveform' do
      before do
        master_file.waveform.content = '{"sample_rate":44100,"bits":8,"samples_per_pixel":183,"length":45288,"data":[]}'
        master_file.waveform.mime_type = 'application/json'
        master_file.save
      end

      it 'does not call the service' do
        expect { job.perform(master_file.id) }.not_to change { master_file.reload.waveform.content }
        expect(service).not_to have_received(:get_waveform_json)
      end

      context 'and regenerate is true' do
        it 'calls the waveform service' do
          expect { job.perform(master_file.id, true) }.to change { master_file.reload.waveform.content }
          expect(service).to have_received(:get_waveform_json)
        end
      end
    end

    context 'when processing fails to generate waveform data' do
      let(:waveform_json) { nil }

      it 'logs and does not set the waveform' do
        expect(Rails.logger).to receive(:error).at_least(:once)
        expect { job.perform(master_file.id, true) }.not_to change { master_file.reload.waveform.content }
        expect(service).to have_received(:get_waveform_json)
      end
    end
  end
end
