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
require 'fakefs/safe'

describe FileMover, type: :service do
  let(:fs_location) { '/path/to/source/test.mp4' }
  let(:fs_file) { FileLocator.new("file://#{fs_location}") }
  let(:fs_dest) { FileLocator.new('file:///path/to/dest/test.mp4') }

  context 's3 methods' do
    let(:s3_file) { FileLocator.new('s3://source_bucket/test.mp4') }
    let(:s3_dest) { FileLocator.new('s3://dest_bucket/test.mp4') }

    before :each do
      @source_object = double(key: 'test.mp4', bucket_name: 'source_bucket')
      allow(Aws::S3::Object).to receive(:new).and_call_original
      allow(Aws::S3::Object).to receive(:new).with(key: 'test.mp4', bucket_name: 'source_bucket').and_return(@source_object)
      allow(@source_object).to receive(:size).and_return(1)
      allow(@source_object).to receive(:delete).and_return(true)
      allow(@source_object).to receive(:download_file).and_return(true)
    end

    describe '.s3_to_s3' do
      it 'copies file from source to dest' do
        expect_any_instance_of(Aws::S3::Object).to receive(:copy_from).with(Aws::S3::Object.new(key: 'test.mp4', bucket_name: 'source_bucket'), multipart_copy: false)
        described_class.s3_to_s3(s3_file, s3_dest)
      end

      it 'deletes file after copying' do
        allow_any_instance_of(Aws::S3::Object).to receive(:copy_from).and_return(true)
        expect(@source_object).to receive(:delete)
        described_class.s3_to_s3(s3_file, s3_dest)
      end
    end

    describe '.s3_to_file' do
      it 'copies file from source to dest' do
        expect(@source_object).to receive(:download_file).with(fs_dest.uri.path)
        described_class.s3_to_file(s3_file, fs_dest)
      end

      it 'deletes file after copying' do
        expect(@source_object).to receive(:delete)
        described_class.s3_to_file(s3_file, fs_dest)
      end
    end

    describe '.file_to_s3' do
      it 'copies file from source to dest' do
        expect_any_instance_of(Aws::S3::Object).to receive(:upload_file).with(fs_file.uri.path)
        described_class.file_to_s3(fs_file, s3_dest)
      end

      it 'deletes file after copying' do
        allow_any_instance_of(Aws::S3::Object).to receive(:upload_file).and_return(true)
        expect(FileUtils).to receive(:rm).with(fs_file.uri.path)
        described_class.file_to_s3(fs_file, s3_dest)
      end
    end
  end

  describe '.file_to_file' do 
    before :each do
      FakeFS.activate!
      FileUtils.mkdir_p File.dirname(fs_location)
      File.open(fs_location, 'w'){}
    end

    after :each do
      FakeFS.deactivate!
    end

    it 'moves file from source to dest' do
      expect(File.exist? fs_location).to be true
      described_class.file_to_file(fs_file, fs_dest)
      expect(File.exist? fs_location).to be false
      expect(File.exist? '/path/to/dest/test.mp4').to be true
    end
  end
end