# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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
end
