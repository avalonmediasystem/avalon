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

describe WaveformJob do
  let(:job) { WaveformJob.new }
  let(:master_file) { FactoryGirl.create(:master_file, :with_media_object) }
  let(:waveform_json) { File.read('spec/fixtures/waveform.json') }

  describe "perform" do
    before do
      allow_any_instance_of(WaveformService).to receive(:get_waveform_json).and_return(waveform_json)
    end

    it 'calls the waveform service and stores the result' do
      job.perform(master_file.id)
      master_file.reload
      expect(master_file.waveform.mime_type).to eq 'application/json'
      expect(master_file.waveform.content).to eq waveform_json
    end

    context 'when on disk' do
      xit 'calls the waveform service with the file location'
    end

    context 'when not on disk' do
      xit 'calls the waveform service with the playlist url'
    end
  end
end
