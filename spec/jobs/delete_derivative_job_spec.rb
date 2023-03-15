# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

describe DeleteDerivativeJob do
  let(:local_file) { 'file:///temp/media_file.mp4' }
  let(:s3_file) { 's3://temp/media_file.mp4' }
  let(:s3_locator) { double("FileLocator::S3File") }
  let(:s3_obj) { Aws::S3::Object.new(bucket_name: "temp", key: "media_file.mp4") }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(FileLocator::S3File).to receive(:new).and_return(s3_locator)
    allow(s3_locator).to receive(:object).and_return(s3_obj)
  end

  describe "perform" do
    context 'local file' do
      it 'gets deleted' do
        expect(File).to receive(:delete).with("/temp/media_file.mp4").once
        DeleteDerivativeJob.perform_now(local_file)
      end
    end

    context 's3 file' do
      it 'gets deleted' do
        expect(s3_obj).to receive(:delete).once
        DeleteDerivativeJob.perform_now(s3_file)
      end
    end
  end
end
