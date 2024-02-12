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

describe SpeedyAF::Proxy::MasterFile do
  let(:master_file) { FactoryBot.create(:master_file) }
  subject(:presenter) { described_class.find(master_file.id) }

  describe 'attributes' do
    let(:master_file) { FactoryBot.create(:master_file, :with_comments, permalink: 'http://permalink', supplemental_files_json: '[]', title: 'Castle', file_checksum: 'abcd1234', file_size: 10, physical_description: 'LP', encoder_classname: 'ActiveEncode::Base', working_file_path: ['path/to/file']) }

    it 'returns all attributes' do
      expect(presenter.permalink).to be_present
      expect(presenter.supplemental_files_json).to be_present
      expect(presenter.title).to be_present
      expect(presenter.file_location).to be_present
      expect(presenter.file_checksum).to be_present
      expect(presenter.file_size).to be_present
      expect(presenter.duration).to be_present
      expect(presenter.display_aspect_ratio).to be_present
      expect(presenter.width).to be_present
      expect(presenter.height).to be_present
      expect(presenter.original_frame_size).to be_present
      expect(presenter.file_format).to be_present
      expect(presenter.poster_offset).to be_present
      expect(presenter.thumbnail_offset).to be_present
      expect(presenter.date_digitized).to be_present
      expect(presenter.physical_description).to be_present
      expect(presenter.masterFile).to be_present
      expect(presenter.identifier).to be_present
      expect(presenter.comment).to be_present
      expect(presenter.workflow_id).to be_present
      expect(presenter.encoder_classname).to be_present
      expect(presenter.workflow_name).to be_present
      expect(presenter.working_file_path).to be_present
    end
  end

  describe "#encoder_class" do
      it "should default to WatchedEncode" do
        expect(subject.encoder_class).to eq(WatchedEncode)
      end

      context 'with workflow name' do
        let(:master_file) { FactoryBot.create(:master_file, workflow_name: 'workflow') }

        it "should infer the class from a workflow name" do
          stub_const("MasterFile::WORKFLOWS", ['workflow'])
          stub_const("WorkflowEncode", Class.new(ActiveEncode::Base))
          expect(subject.encoder_class).to eq(WorkflowEncode)
        end
      end

      context 'with bad workflow name' do
        let(:master_file) { FactoryBot.create(:master_file, workflow_name: 'nonexistent_workflow_encoder') }
        it "should fall back to Watched when a workflow class can't be resolved" do
          stub_const("MasterFile::WORKFLOWS", ['nonexistent_workflow_encoder'])
          expect(subject.encoder_class).to eq(WatchedEncode)
        end
      end

      context 'with invalid class name' do
        let(:master_file) { FactoryBot.create(:master_file, encoder_classname: 'my-awesomeEncode') }
        it "should fall back to Watched when a workflow class can't be resolved" do
          expect(subject.encoder_class).to eq(WatchedEncode)
        end
      end

      context 'with encoder class name' do
        let(:master_file) { FactoryBot.create(:master_file, encoder_classname: 'EncoderModule::MyEncoder') }
        it "should resolve an explicitly named encoder class" do
          stub_const("EncoderModule::MyEncoder", Class.new(ActiveEncode::Base))
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
          stub_const("EncoderModule::MyEncoder", Class.new(ActiveEncode::Base))
          expect(subject.encoder_classname).to eq('EncoderModule::MyEncoder')
        end
      end

      context 'with an encoder class named after the engine adapter' do
        it "should find the encoder class" do
          stub_const("TestEncode", Class.new(ActiveEncode::Base))
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
