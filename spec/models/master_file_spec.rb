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

      logger.debug "#{mf.pid}: #{mf.relationships.to_a.to_s}"
      logger.debug "#{derivative.pid}: #{derivative.relationships.to_a.to_s}"

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
    subject(:masterfile) { MasterFile.create }
    it "should delete when parent is nil (VOV-1357)" do
      pending "bugfix"      
      expect { masterfile.delete }.to change(MasterFile.all.count).by(-1)
    end
  end
end
