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

describe SpeedyAF::Proxy::MasterFile do
  let(:master_file) { FactoryBot.create(:master_file) }
  subject(:presenter) { described_class.find(master_file.id) }

  describe "#encoder_class" do
      before :all do
        class WorkflowEncode < ActiveEncode::Base
        end

        module EncoderModule
          class MyEncoder < ActiveEncode::Base
          end
        end
      end

      after :all do
        EncoderModule.send(:remove_const, :MyEncoder)
        Object.send(:remove_const, :EncoderModule)
        Object.send(:remove_const, :WorkflowEncode)
      end

      before do
        stub_const("MasterFile::WORKFLOWS", ['fullaudio', 'avalon', 'pass_through', 'avalon-skip-transcoding', 'avalon-skip-transcoding-audio', 'workflow', 'nonexistent_workflow_encoder'])
      end

      it "should default to WatchedEncode" do
        expect(subject.encoder_class).to eq(WatchedEncode)
      end

      context 'with workflow name' do
        let(:master_file) { FactoryBot.create(:master_file, workflow_name: 'workflow') }
        it "should infer the class from a workflow name" do
          expect(subject.encoder_class).to eq(WorkflowEncode)
        end
      end

      context 'with bad workflow name' do
        let(:master_file) { FactoryBot.create(:master_file, workflow_name: 'nonexistent_workflow_encoder') }
        it "should fall back to Watched when a workflow class can't be resolved" do
          expect(subject.encoder_class).to eq(WatchedEncode)
        end
      end

      context 'with encoder class name' do
        let(:master_file) { FactoryBot.create(:master_file, encoder_classname: 'EncoderModule::MyEncoder') }
        it "should resolve an explicitly named encoder class" do
          expect(subject.encoder_class).to eq(EncoderModule::MyEncoder)
        end
      end

      context 'with bad encoder class name' do
        let(:master_file) { FactoryBot.create(:master_file, encoder_classname: 'EncoderModule::NonexistentEncoder') }
        it "should fall back to WatchedEncode when an encoder class can't be resolved" do
          expect(subject.encoder_class).to eq(WatchedEncode)
        end
      end

      context 'with bad encoder class name' do
        let(:master_file) { FactoryBot.create(:master_file, encoder_class: EncoderModule::MyEncoder) }
        it "should correctly set the encoder classname from the encoder" do
          expect(subject.encoder_classname).to eq('EncoderModule::MyEncoder')
        end
      end

      context 'with an encoder class named after the engine adapter' do
        before :all do
          class TestEncode < ActiveEncode::Base
          end
        end
    
        after :all do
          Object.send(:remove_const, :TestEncode)
        end
    
        it "should find the encoder class" do
          expect(Settings.encoding.engine_adapter).to eq "test"
          expect(subject.encoder_class).to eq(TestEncode)
        end
      end
  end

  context 'supplemental_files' do
    let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
    let(:supplemental_files) { [supplemental_file] }
    let(:supplemental_files_json) { [supplemental_file.to_global_id.to_s].to_json }
    let(:master_file) { FactoryBot.create(:master_file, supplemental_files_json: supplemental_files_json) }

    it 'reifies the supplemental files from the stored json string' do
      expect(presenter.supplemental_files).to eq supplemental_files
    end
  end
end