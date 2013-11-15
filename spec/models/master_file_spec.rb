# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

require 'spec_helper'

describe MasterFile do
#  describe "container" do
#    it "should set relationships on self and container" do
#      mf = MasterFile.new
#      mo = MediaObject.new
#      mo.save(validate: false)
#      mf.relationships_by_name[:self]["part_of"].size.should == 0
#      mo.relationships_by_name[:self]["parts"].size.should == 0
#      mf.mediaobject = mo
#      mf.relationships_by_name[:self]["part_of"].size.should == 1
#      mf.relationships_by_name[:self]["part_of"].first.should eq "info:fedora/#{mo.pid}"
#      mo.relationships_by_name[:self]["parts"].size.should == 1
#      mo.relationships_by_name[:self]["parts"].first.should eq "info:fedora/#{mf.pid}"
#      mf.relationships_are_dirty.should be true
#      mo.relationships_are_dirty.should be true
#    end
#  end

  describe "masterfiles=" do
    it "should set hasDerivation relationships on self" do
      derivative = Derivative.new
      mf = MasterFile.new
      mf.save
      derivative.save

      mf.relationships(:is_derivation_of).size.should == 0

      mf.derivatives += [derivative]

      derivative.relationships(:is_derivation_of).size.should == 1
      derivative.relationships(:is_derivation_of).first.should == mf.internal_uri

      #derivative.relationships_are_dirty.should be true
    end
  end

  describe '#finished_processing?' do
    describe 'classifying statuses' do
      let(:master_file){ MasterFile.new }
      it 'returns true for stopped' do
        master_file.status_code = ['STOPPED']
        master_file.finished_processing?.should be_true
      end
      it 'returns true for succeeded' do
        master_file.status_code = ['SUCCEEDED']
        master_file.finished_processing?.should be_true
      end
      it 'returns true for failed' do
        master_file.status_code = ['FAILED']
        master_file.finished_processing?.should be_true
      end
    end
  end

  describe "delete" do
    subject(:masterfile) { derivative.masterfile }
    let(:derivative) {FactoryGirl.create(:derivative)}
    it "should delete (VOV-1805)" do
      Rubyhorn.stub_chain(:client,:delete_track).and_return("http://test.com/retract_rtmp.xml")
      Rubyhorn.stub_chain(:client,:delete_hls_track).and_return("http://test.com/retract_hls.xml")
      masterfile
      expect { masterfile.delete }.to change { MasterFile.all.count }.by(-1)
    end

    it "should delete with a nil parent (VOV-1357)" do
      pending "bugfix"      
      masterfile.mediaobject = nil
      masterfile.save
      expect { masterfile.delete }.to change { MasterFile.all.count }.by(-1)
    end
  end

  describe "image_offset" do
    subject(:master_file) {FactoryGirl.create(:master_file, duration: (rand(21600000)+60000).to_s )}

    describe "milliseconds" do
      it "should accept a value" do
        offset = master_file.duration.to_i / 2
        master_file.poster_offset = offset
        master_file.poster_offset.should == offset.to_s
        master_file.should be_valid
      end

      it "should complain if value < 0" do
        master_file.poster_offset = -1
        master_file.should_not be_valid
        master_file.errors[:poster_offset].first.should == "must be between 0 and #{master_file.duration}"
      end

      it "should complain if value > duration" do
        offset = master_file.duration.to_i + rand(32514) + 500
        master_file.poster_offset = offset
        master_file.should_not be_valid
        master_file.errors[:poster_offset].first.should == "must be between 0 and #{master_file.duration}"
      end
    end

    describe "hh:mm:ss.sss" do
      it "should accept a value" do
        offset = master_file.duration.to_i / 2
        master_file.poster_offset = offset.to_hms
        master_file.poster_offset.should == offset.to_s
        master_file.should be_valid
      end

      it "should complain if value > duration" do
        offset = master_file.duration.to_i + rand(32514) + 500
        master_file.poster_offset = offset.to_hms
        master_file.should_not be_valid
        master_file.errors[:poster_offset].first.should == "must be between 0 and #{master_file.duration}"
      end
    end

    describe "update images" do
      it "should update on save" do
        MasterFile.should_receive(:extract_still).with(master_file.pid,{type:'both',offset:'12345'})
        master_file.poster_offset = 12345
        master_file.save
      end
    end
  end

  describe "#set_workflow" do
    let (:master_file) {MasterFile.new}
    describe "custom workflow" do
      it "should not use the passed workflow if it is not in the WORKFLOWS list" do
        master_file.file_format = 'Moving image'
        master_file.set_workflow('bad-workflow')
        master_file.workflow_name.should == 'avalon'
      end 
      it "should use the passed workflow if it is in the WORKFLOWS list" do
        master_file.file_format = 'Moving image'
        master_file.set_workflow(MasterFile::WORKFLOWS.first)
        master_file.workflow_name.should == MasterFile::WORKFLOWS.first
      end 
    end
    describe "video" do
      it "should use the avalon workflow" do
        master_file.file_format = 'Moving image'
        master_file.set_workflow
        master_file.workflow_name.should == 'avalon'
      end 
    end
    describe "audio" do
      it "should use the fullaudio workflow" do
        master_file.file_format = 'Sound'
        master_file.set_workflow
        master_file.workflow_name.should == 'fullaudio'
      end
    end
    describe "unknown format" do
      it "should set workflow_name to nil" do
        master_file.file_format = 'Unknown'
        master_file.set_workflow
        master_file.workflow_name.should == nil
      end
    end
  end
end
