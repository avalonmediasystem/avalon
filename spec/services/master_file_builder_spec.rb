# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

describe MasterFileBuilder, type: :service do
  describe 'Upload notice' do
    it "should give correct notice" do
      expect(MasterFileBuilder.create_upload_notice("Sound")).to include "audio"
      expect(MasterFileBuilder.create_upload_notice("Moving image")).to include "video"
      expect(MasterFileBuilder.create_upload_notice("Excel")).to include "could not be identified"
    end
  end

  describe 'FileUpload.build' do
    context "with upload limit enabled" do
      around do |example|
        @old_maximum_upload_size = MasterFile::MAXIMUM_UPLOAD_SIZE
        MasterFile::MAXIMUM_UPLOAD_SIZE = 2.gigabytes
        example.run
        MasterFile::MAXIMUM_UPLOAD_SIZE = @old_maximum_upload_size
      end

     it "should raise error if file is too big" do
        file = double("file", size: MasterFile::MAXIMUM_UPLOAD_SIZE + 1)
        params = { Filedata: [file] }
        expect { MasterFileBuilder::FileUpload.build(params) }.to raise_error MasterFileBuilder::BuildError
      end

      it "should return a Spec for legit file" do
        file = double("file", size: MasterFile::MAXIMUM_UPLOAD_SIZE - 1, original_filename: "aname", content_type: "mp4")
        params = { Filedata: [file], workflow: double("workflow") }
        s = MasterFileBuilder::FileUpload.build(params)
        expect(s).to eq [MasterFileBuilder::Spec.new(file, file.original_filename, file.content_type, params[:workflow])]
      end
    end

    it "should not raise error when no limit" do
      expect(MasterFile::MAXIMUM_UPLOAD_SIZE.is_a? Numeric).to eq false
      file = double("file", size: 2.gigabytes + 1)
      params = { Filedata: [file] }
      expect { MasterFileBuilder::FileUpload.build(params) }.not_to raise_error MasterFileBuilder::BuildError
    end
  end

  describe 'DropboxUpload.build' do
    it "should return a Spec" do
      url = "file:///srv/dropbox/file.mp4"
      params = ActionController::Parameters.new({ workflow: double("workflow"), selected_files: { afile: { url: url } } })

      s = MasterFileBuilder::DropboxUpload.build(params)
      expect(s).to eq [MasterFileBuilder::Spec.new(Addressable::URI.parse(url), "file.mp4", "video/mp4", params[:workflow])]
    end
  end

  describe 'build' do
    it "should return error message" do
      mo = double(MediaObject)
      s = MasterFileBuilder.build(mo, {})
      expect(s[:flash][:error]).to be_present
      expect(s[:flash][:master_files]).to be_blank
    end
  end
end
