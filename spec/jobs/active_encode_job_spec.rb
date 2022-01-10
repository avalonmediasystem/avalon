# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

describe ActiveEncodeJobs do
  describe ActiveEncodeJobs::CreateEncodeJob do
    let(:master_file) { FactoryBot.create(:master_file, workflow_id: nil, encoder_class: encoder_class ) }
    let(:encoder_class) { FfmpegEncode }
    let(:input) { "file://path/to/file" }

    describe "perform" do
      it 'creates the active_encode job' do
        expect(encoder_class).to receive(:create).with(input, master_file_id: master_file.id, preset: master_file.workflow_name).once
        ActiveEncodeJobs::CreateEncodeJob.perform_now(input, master_file.id)
      end

      context 'when master file does not exist' do
        it 'does not create the active_encode_job' do
          expect(encoder_class).not_to receive(:create)
          ActiveEncodeJobs::CreateEncodeJob.perform_now(input, 'bad-id')
        end
      end

      context 'when master file has already been processed' do
        let(:master_file) { FactoryBot.create(:master_file, workflow_id: '12345', encoder_class: encoder_class ) }

        it 'does not create the active_encode_job' do
          expect(encoder_class).not_to receive(:create)
          ActiveEncodeJobs::CreateEncodeJob.perform_now(input, master_file.id)
        end
      end
    end
  end

  describe ActiveEncodeJobs::CancelEncodeJob do
    let(:master_file) { FactoryBot.create(:master_file, workflow_id: '12345', encoder_class: encoder_class ) }
    let(:encoder_class) { FfmpegEncode }
    let(:input) { "file://path/to/file" }
    let(:encode) { double() }
    
    before do
      allow(encoder_class).to receive(:find).and_return(encode)
    end

    describe "perform" do
      context 'when master file does not exist' do
        it 'does not do anything' do
          expect(encode).not_to receive(:try).with(:cancel!)
          ActiveEncodeJobs::CancelEncodeJob.perform_now('wfid', 'bad-id')
        end
      end

      context 'when master file has already been processed' do
        let(:master_file) { FactoryBot.create(:master_file, :completed_processing, encoder_class: encoder_class ) }
        it 'does not do anything' do
          expect(encoder_class).not_to receive(:try).with(:cancel!)
          ActiveEncodeJobs::CancelEncodeJob.perform_now('wfid', master_file.id)
        end
      end

      context 'when master file is being processed' do
        it 'calls ActiveEncode.cancel' do
          expect(encode).to receive(:try).with(:cancel!)
          ActiveEncodeJobs::CancelEncodeJob.perform_now('wfid', master_file.id)
        end
      end
    end
  end
end
