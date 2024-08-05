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

describe FileLocator, type: :service do
  describe 'S3File Class' do
    let(:bucket) { "mybucket" }
    let(:key) { "mykey.mp4" }
    let(:s3file) { FileLocator::S3File.new("s3://#{bucket}/#{key}") }

    it "should be able to initialize from an S3 URI" do
      expect(s3file.bucket).to eq bucket
      expect(s3file.key).to eq key
    end

    it "should return an S3 Object" do
      s3_object = s3file.object
      expect(s3_object).to be_an Aws::S3::Object
      expect(s3_object.bucket_name).to eq bucket
      expect(s3_object.key).to eq key
    end

    describe '#download_url' do
      subject { URI.parse(s3file.download_url) }

      context "with minio public host enabled" do
        before do
          Settings.minio = double("minio", endpoint: "http://minio:9000", public_host: "http://domain:9000", access: 'admin', secret: 'admin')
        end

        it "should return a presigned url using the minio public host address" do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('AWS_REGION').and_return('us-east-2')
          expect(subject.host).to eq 'mybucket.domain'
          expect(subject.path).to eq '/mykey.mp4'
          expect(subject.query).to include('response-content-disposition=attachment%3B%20filename%3Dmykey.mp4', 'X-Amz-Algorithm', 
                                           'X-Amz-Credential', 'X-Amz-Expires', 'X-Amz-SignedHeaders', 'X-Amz-Signature')
        end

        after do
          Settings.minio = nil
        end
      end

      context "without minio public host enabled" do
        it "should return a presigned url using the AWS host address" do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('AWS_REGION').and_return('us-east-2')
          expect(subject.host).to eq 'mybucket.s3.us-stubbed-1.amazonaws.com'
          expect(subject.path).to eq '/mykey.mp4'
          expect(subject.query).to include('response-content-disposition=attachment%3B%20filename%3Dmykey.mp4', 'X-Amz-Algorithm', 
                                           'X-Amz-Credential', 'X-Amz-Expires', 'X-Amz-SignedHeaders', 'X-Amz-Signature')
        end
      end
    end
  end

  describe "Local file" do
    let(:path) { "/path/to/file.mp4" }
    let(:source) { "file://#{path}" }
    let(:locator) { FileLocator.new(source) }

    it "should return the correct uri" do
      expect(locator.uri).to eq Addressable::URI.parse(source)
    end

    it "should return the correct location" do
      expect(locator.location).to eq path
    end

    it "should tell if file exists" do
      allow(File).to receive(:exist?).with(path) { true }
      expect(locator.exist?).to be_truthy
    end

    context "return file" do
      let(:file) { double(File) }
      before :each do
        allow(File).to receive(:open).and_return file
      end

      it "should return reader" do
        expect(locator.reader).to eq file
      end

      it "should return attachment" do
        expect(locator.attachment).to eq file
      end
    end

    context "filename with reserved characters" do
      let(:path) { "/path/to/file?#.mp4" }

      it "should return the correct location" do
        expect(locator.location).to eq path
      end
    end
  end

  describe "s3 file" do
    let(:bucket) { "mybucket" }
    let(:key) { "mykey.mp4" }
    let(:source) { "s3://#{bucket}/#{key}" }
    let(:locator) { FileLocator.new(source) }

    it "should return the correct uri" do
      expect(locator.uri).to eq Addressable::URI.parse(source)
    end

    it "should return the correct location" do
      expect(locator.location).to start_with "https://#{bucket}.s3.us-stubbed-1.amazonaws.com/#{key}"
    end

    it "should tell if file exists" do
      expect(locator.exist?).to be_truthy
    end

    it "should return reader" do
      expect(locator.reader).to be_a StringIO
    end

    it "should return attachment" do
      expect(locator.attachment).to eq Addressable::URI.parse(source)
    end
  end

  describe "Other file" do
    let(:path) { "/path/to/file.mp4" }
    let(:source) { "bogus://#{path}" }
    let(:locator) { FileLocator.new(source) }

    it "should return the correct uri" do
      expect(locator.uri).to eq Addressable::URI.parse(source)
    end

    it "should return the correct location" do
      expect(locator.location).to eq source
    end

    it "should tell if file exists" do
      expect(locator.exist?).to be_falsy
    end

    it "should return reader" do
      io = double(IO)
      allow(Kernel).to receive(:open).and_return io
      expect(locator.reader).to eq io
    end

    it "should return attachment" do
      expect(locator.attachment).to eq locator.location
    end
  end

  describe "remove directory" do
    describe '#remove_fs_dir' do
      let(:file_path) { "/tmp/dropbox/test/mykey.mp4" }
      let(:locator) { FileLocator.new(file_path) }
  
      it 'deletes fs dir' do
        allow(File).to receive(:exist?).with(file_path) { true }
        expect(locator.exist?).to be_truthy
        FileLocator.remove_dir("file://tmp/dropbox/test")
        allow(File).to receive(:exist?).with(file_path) { false }
        expect(locator.exist?).to be_falsey
      end
    end
  
    describe '#remove_s3_dir' do
      let(:old_bucket) { Settings.encoding.masterfile_bucket }
      let(:old_path) { Settings.dropbox.path }

      let(:dropbox_path) { "s3://#{test_bucket}/dropbox/test_collection" }
      let(:test_bucket) { "test_bucket" }
      let(:dropbox_prefix) { "/dropbox/test_collection/"}
      let(:s3_res) { Aws::S3::Resource.new }
      let(:s3_bucket) { Aws::S3::Bucket.new(test_bucket) }

      let(:s3_directory) { Aws::S3::Object.new(bucket_name: test_bucket, key: "/dropbox/test_collection/") }
      let(:s3_contents) { Aws::S3::ObjectSummary::Collection.new(bucket_name: test_bucket, key: "/dropbox/test_collection/testkey.mp3") }

      before do
        Settings.encoding.masterfile_bucket = test_bucket

        allow(Aws::S3::Resource).to receive(:new).and_return(s3_res)
        allow(s3_res).to receive(:bucket).and_return(s3_bucket)
        allow(s3_bucket).to receive(:object).with(dropbox_prefix).and_return(s3_directory)
        allow(s3_bucket).to receive(:objects).with(prefix: dropbox_prefix).and_return(s3_contents)

        # when dir is empty
        allow(s3_directory).to receive(:exists?).and_return(true)
        allow(s3_directory).to receive(:delete)

        # when there's files in the dir
        allow(s3_contents).to receive(:batch_delete!)
      end

      it 'when empty' do
        expect(s3_bucket).to receive(:object).with(dropbox_prefix)
        expect(s3_directory).to receive(:exists?)
        expect(s3_directory).to receive(:delete).once
        FileLocator.remove_s3_dir(dropbox_path)
      end

      it 'when there\'s files inside' do
        expect(s3_bucket).to receive(:objects).with(prefix: dropbox_prefix)
        expect(s3_contents).to receive(:batch_delete!).once
        FileLocator.remove_s3_dir(dropbox_path)
      end

      after do
        Settings.encoding.masterfile_bucket = old_bucket
      end
    end
  end
end
