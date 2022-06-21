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
require 'fakefs/safe'
require 'file_locator'

describe MasterFileManagementJobs do

  context "fakefs" do

    let(:location) { "/path/to/old/file.mp4" }
    let!(:master_file) { FactoryBot.create(:master_file, file_location: location) }

    before :each do
      FakeFS.activate!
      FileUtils.mkdir_p File.dirname(location)
      File.open(location, 'w'){}
    end

    describe "delete_masterfile" do
      it "should delete masterfile" do
        MasterFileManagementJobs::Delete.perform_now(master_file.id)
        expect(File.exists? location).to be false
        expect(MasterFile.find(master_file.id).file_location).to be_blank
      end
    end

    describe "move_masterfile" do
      it "should move masterfile" do
        newpath = "/path/to/new/file.mp4"
        MasterFileManagementJobs::Move.perform_now(master_file.id, newpath)
        expect(File.exists? location).to be false
        expect(File.exists? newpath).to be true
        expect(newpath).to eq MasterFile.find(master_file.id).file_location
      end

      it 'does nothing if masterfile already moved' do
        newpath = master_file.file_location
        MasterFileManagementJobs::Move.perform_now(master_file.id, newpath)
        expect(File.exists? location).to be true
        expect(File.exists? newpath).to be true
        expect(newpath).to eq MasterFile.find(master_file.id).file_location
      end
    end

    describe "move_masterfile with space in filename" do
      let(:location) { "/path/to/old/file with space.mp4" }
      it "should move masterfile with space in filename" do
        newpath = "/path/to/new/file with space.mp4"
        MasterFileManagementJobs::Move.perform_now(master_file.id, newpath)
        expect(File.exists? location).to be false
        expect(File.exists? newpath).to be true
        expect(newpath).to eq MasterFile.find(master_file.id).file_location
      end
    end

    after :each do
      FakeFS.deactivate!
    end
  end
end
