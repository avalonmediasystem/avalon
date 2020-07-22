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
require 'aws-sdk-s3'

describe DeleteDropboxJob do
  let(:fs_dropbox) { '/temp/dropbox/test_collection' }
  let(:fs_locator) { FileLocator.new(fs_dropbox) }
  let(:s3_dropbox) { 's3://temp/dropbox/test_collection' }
  let(:s3_locator) { FileLocator.new(s3_dropbox) }
  let(:old_path) { Settings.dropbox.path }

  describe "perform" do
    before do
      allow(FileLocator).to receive(:new).and_return(fs_locator)
    end

    context 'using filesystem' do
      it 'calls destroy_fs_dropbox_directory' do
        expect(fs_locator).to receive(:destroy_fs_dropbox_directory).with(fs_dropbox).once
        DeleteDropboxJob.perform_now(fs_dropbox)
      end
    end

    context 'using s3' do
      before do
        Settings.dropbox.path = "s3://temp/dropbox"
        allow(FileLocator).to receive(:new).and_return(s3_locator)
      end

      it 'calls destroy_s3_dropbox_directory' do
        expect(s3_locator).to receive(:destroy_s3_dropbox_directory).with(s3_dropbox).once
        DeleteDropboxJob.perform_now(s3_dropbox)
      end

      after do
        Settings.dropbox.path = old_path
      end
    end
  end
end
