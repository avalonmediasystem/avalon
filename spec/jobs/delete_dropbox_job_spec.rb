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
  let(:fs_dropbox) { 'file://temp/dropbox/test_collection' }
  let(:s3_dropbox) { 's3://temp/dropbox/test_collection' }

  describe "perform" do
    it 'deletes filesystem dir' do
      expect(FileLocator).to receive(:remove_dir).with(fs_dropbox).once
      DeleteDropboxJob.perform_now(fs_dropbox)
    end

    it 'deletes s3 dir' do
      expect(FileLocator).to receive(:remove_dir).with(s3_dropbox).once
      DeleteDropboxJob.perform_now(s3_dropbox)
    end
  end
end
