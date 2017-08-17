# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

describe Avalon::Batch::Entry do
  let(:testdir) {'spec/fixtures/dropbox/dynamic'}
  let(:filename) {File.join(testdir,'video.mp4')}
  let(:collection) {FactoryGirl.build(:collection)}
  let(:manifest) do
    manifest = double()
    allow(manifest).to receive_message_chain(:package, :dir).and_return(testdir)
    allow(manifest).to receive_message_chain(:package, :user, :user_key).and_return('archivist1@example.org')
    allow(manifest).to receive_message_chain(:package, :collection).and_return(collection)
    manifest
  end
  let(:entry_fields) {{ title: Faker::Lorem.sentence, date_issued: "#{Time.now}", collection: collection }}
  let(:entry_files) { [{ file: filename, skip_transcoding: false }] }
  let(:entry_opts) { {} }
  let(:entry) { Avalon::Batch::Entry.new(entry_fields, entry_files, entry_opts, nil, manifest) }

  before(:each) do
    #FakeFS.activate!
    #FakeFS::FileSystem.clone(File.join(Rails.root, "config"))
    FileUtils.mkdir_p(testdir)
    FileUtils.touch(filename)
  end

  after(:each) do
    FileUtils.rm(filename)
    FileUtils.rmdir(testdir)
    #FakeFS.deactivate!
  end

  describe '#file_valid?' do
    it 'should be valid if the file exists' do
      expect(entry.file_valid?({file: filename})).to be_truthy
      expect(entry.errors).to be_empty
    end
    it 'should be valid if masterfile exists and it is not skip-transcoding' do
      allow(Avalon::Batch::Entry).to receive(:derivativePaths).and_return([])
      expect(entry.file_valid?({file: filename, skip_transcoding: false})).to be_truthy
      expect(entry.errors).to be_empty
    end
    it 'should be valid if masterfile exists and it is skip-transcoding' do
      allow(Avalon::Batch::Entry).to receive(:derivativePaths).and_return([])
      expect(entry.file_valid?({file: filename, skip_transcoding: true})).to be_truthy
      expect(entry.errors).to be_empty
    end
    it 'should be invalid if pretranscoded derivatives exist and it is not skip-transcoding' do
      allow(Avalon::Batch::Entry).to receive(:derivativePaths).and_return(['derivative.low.mp4', 'derivative.medium.mp4', 'derivative.high.mp4'])
      expect(entry.file_valid?({file: 'derivative.mp4', skip_transcoding: false})).to be_falsey
      expect(entry.errors).not_to be_empty
    end
    it 'should be valid if pretranscoded derivatives exist and it is skip-transcoding' do
      allow(Avalon::Batch::Entry).to receive(:derivativePaths).and_return(['derivative.low.mp4', 'derivative.medium.mp4', 'derivative.high.mp4'])
      expect(entry.file_valid?({file: 'derivative.mp4', skip_transcoding: true})).to be_truthy
      expect(entry.errors).to be_empty
    end
    it 'should be invalid if neither the file nor derivatives exist - not skip transcode' do
      expect(entry.file_valid?({file: 'nonexistent.mp4', skip_transcoding: false})).to be_falsey
      expect(entry.errors).not_to be_empty
    end
    it 'should be invalid if neither the file nor derivatives exist - skip transcode' do
      allow(Avalon::Batch::Entry).to receive(:derivativePaths).and_return([])
      expect(entry.file_valid?({file: 'derivative.mp4', skip_transcoding: true})).to be_falsey
      expect(entry.errors).not_to be_empty
    end
    it 'should be invalid if both file and derivatives exist and it is not skip-transcoding' do
      allow(Avalon::Batch::Entry).to receive(:derivativePaths).and_return(['video.low.mp4', 'video.medium.mp4', 'video.high.mp4'])
      expect(entry.file_valid?({file: filename, skip_transcoding: false})).to be_falsey
      expect(entry.errors).not_to be_empty
    end
    it 'should be invalid if both file and derivatives exist and it is skip-transcoding' do
      allow(Avalon::Batch::Entry).to receive(:derivativePaths).and_return(['video.low.mp4', 'video.medium.mp4', 'video.high.mp4'])
      expect(entry.file_valid?({file: filename, skip_transcoding: true})).to be_falsey
      expect(entry.errors).not_to be_empty
    end
  end

  describe '#gatherFiles' do
    it 'should return a file when no pretranscoded derivatives exist' do
      expect(FileUtils.cmp(Avalon::Batch::Entry.gatherFiles(filename), filename)).to be_truthy
    end
  end

  describe 'with multiple pretranscoded derivatives' do
    let(:filename) {'videoshort.mp4'}
    %w(low medium high).each do |quality|
      let("filename_#{quality}".to_sym) {"videoshort.#{quality}.mp4"}
    end
    let(:derivative_paths) {[filename_low, filename_medium, filename_high]}
    let(:derivative_hash) {{'quality-low' => File.new(filename_low), 'quality-medium' => File.new(filename_medium), 'quality-high' => File.new(filename_high)}}


    before(:each) do
      derivative_paths.each {|path| FileUtils.touch(path)}
    end

    after(:each) do
      derivative_paths.each {|path| FileUtils.rm(path)}
    end

    describe '#process' do
      let(:entry) do
        Avalon::Batch::Entry.new({ title: Faker::Lorem.sentence, date_issued: "#{Time.now}", collection: collection }, [{file: filename, skip_transcoding: true}], {}, nil, manifest)
      end

      before(:each) do
        derivative_paths.each {|path| FileUtils.touch(File.join(testdir,path))}
      end
      after(:each) do
        derivative_paths.each {|path| FileUtils.rm(File.join(testdir,path))}
      end

      it 'should call MasterFile.setContent with a hash of derivatives' do
      	allow_any_instance_of(MasterFile).to receive(:file_format).and_return('Moving image')
      	expect_any_instance_of(MasterFile).to receive(:setContent).with(hash_match(derivative_hash))
      	expect_any_instance_of(MasterFile).to receive(:process).with(hash_match(derivative_hash))
      	entry.process!
      end
    end

    describe '#gatherFiles' do
      it 'should return a hash of files keyed with their quality' do
	expect(Avalon::Batch::Entry.gatherFiles(filename)).to hash_match derivative_hash
      end
    end

    describe '#derivativePaths' do
      it 'should return the paths to all derivative files that exist' do
	expect(Avalon::Batch::Entry.derivativePaths(filename)).to eq derivative_paths
      end
    end

    describe '#derivativePath' do
      it 'should insert supplied quality into filename' do
	expect(Avalon::Batch::Entry.derivativePath(filename, 'low')).to eq filename_low
      end
    end
  end

  describe 'hidden' do
    let(:entry_hidden) { Avalon::Batch::Entry.new(entry_fields, entry_files, {hidden: true}, nil, manifest) }
    it 'does not set hidden on the media objects if the entry is not hidden' do
      expect(entry.media_object).not_to be_hidden
    end
    it 'sets hidden on the media objects if the entry is hidden' do
      expect(entry_hidden.media_object).to be_hidden
    end
  end

  describe 'avalon_uploader' do
    it 'sets avalon_uploader on the media object' do
      expect(entry.media_object.avalon_uploader).to eq('archivist1@example.org')
    end
  end
end
