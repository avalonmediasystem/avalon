# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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

describe Avalon::Batch::Entry do

  RSpec::Matchers.define :hash_match do |expected|
    match do |actual|
      diff = HashDiff.diff(actual,expected) do |p,a,e|
        if a.is_a?(RealFile) && e.is_a?(RealFile)
          FileUtils.cmp(a,e)
        elsif a.is_a?(File) && e.is_a?(File)
          FileUtils.cmp(a,e)
        elsif p == ""
           nil
        else
          a.eql? e
        end
      end
      diff == []
    end
  end
  let(:testdir) {'spec/fixtures/dropbox/dynamic'}
  let(:filename) {'videoshort.mp4'}
  %w(low medium high).each do |quality|
    let("filename_#{quality}".to_sym) {"videoshort.#{quality}.mp4"}
  end
  let(:derivative_paths) {[filename_low, filename_medium, filename_high]}
  let(:derivative_hash) {{'quality-low' => File.new(filename_low), 'quality-medium' => File.new(filename_medium), 'quality-high' => File.new(filename_high)}}


  before(:each) do
    #FakeFS.activate!
    derivative_paths.each {|path| FileUtils.touch(path)}
  end

  after(:each) do
    #FakeFS.deactivate!
  end

  describe '#process' do
    let(:collection) {FactoryGirl.create(:collection)}
    it 'should should call MasterFile.setContent with a hash or derivatives' do
      manifest = double()
      manifest.stub_chain(:package, :dir).and_return(testdir)
      manifest.stub_chain(:package, :user, :user_key).and_return('archivist1@example.org')
      manifest.stub_chain(:package, :collection).and_return(collection)

      entry = Avalon::Batch::Entry.new({ title: Faker::Lorem.sentence, date_issued: "#{Time.now}", collection: collection, governing_policy: collection }, [{file: filename, skip_transcoding: true}], {}, nil, manifest)
      expect_any_instance_of(MasterFile).to receive(:setContent).with(hash_match(derivative_hash))
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
