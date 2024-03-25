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

describe Avalon::Batch::Entry do
  let(:testdir) {'spec/fixtures/'}
  let(:filename) {'videoshort.mp4'}
  let(:collection) {FactoryBot.build(:collection)}
  let(:entry_fields) {{ title: Faker::Lorem.sentence, date_issued: "#{DateTime.now.strftime('%F')}" }}
  let(:entry_files) { [{ file: File.join(testdir, filename), skip_transcoding: false }] }
  let(:entry_opts) { {user_key: 'archivist1@example.org', collection: collection} }
  let(:entry) { Avalon::Batch::Entry.new(entry_fields, entry_files, entry_opts, nil, nil) }

  describe '#file_valid?' do
    let(:filename) { 'spec/fixtures/dropbox/example_batch_ingest/assets/Vid1-1.mp4' }
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
    let(:filename) { File.join(Rails.root, "spec/fixtures/jazz-performance.mp3") }
    it 'should return a file when no pretranscoded derivatives exist' do
      expect(FileUtils.cmp(Avalon::Batch::Entry.gatherFiles(filename), filename)).to be_truthy
    end
  end

  describe 'with multiple pretranscoded derivatives' do
    let(:filename) {File.join(Rails.root, "spec/fixtures/videoshort.mp4")}
    %w(low medium high).each do |quality|
      let("filename_#{quality}".to_sym) {File.join(Rails.root, "spec/fixtures/videoshort.#{quality}.mp4")}
    end
    let(:derivative_paths) {[filename_low, filename_medium, filename_high]}
    let(:derivative_hash) {{'quality-low' => File.new(filename_low), 'quality-medium' => File.new(filename_medium), 'quality-high' => File.new(filename_high)}}

    describe '#process' do
      let(:entry) do
        Avalon::Batch::Entry.new({ title: Faker::Lorem.sentence, date_issued: "#{Time.now}" }, [{file: File.join(testdir, "videoshort.mp4"), skip_transcoding: true}], entry_opts, nil, nil)
      end

      it 'should call MasterFile.setContent with a hash of derivatives' do
      	allow_any_instance_of(MasterFile).to receive(:file_format).and_return('Moving image')
        expect_any_instance_of(MasterFile).to receive(:setContent).with(hash_match(derivative_hash), dropbox_dir: entry.media_object.collection.dropbox_absolute_path)
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
    let(:entry_hidden) { Avalon::Batch::Entry.new(entry_fields, entry_files, entry_opts.merge({hidden: true}), nil, nil) }
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

  describe 'bibliographic import' do
    let(:bib_id) { '7763100' }
    let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=#{bib_id}" }
    let(:sru_response) { File.read(File.expand_path("../../../../fixtures/#{bib_id}.xml",__FILE__)) }
    let(:entry_fields) {{ bibliographic_id: [bib_id], bibliographic_id_label: ['local'] }}
    before do
      stub_request(:get, sru_url).to_return(body: sru_response)
    end
    it 'retrieves bib data' do
      expect(entry.errors).to be_empty
      expect(entry.media_object.bibliographic_id).to eq({:source=>"local", :id=>bib_id})
      expect(entry.media_object.title).to eq('245 A : B F G K N P S')
    end
  end

  describe 'other identifiers' do
    let(:entry_fields) {{ title: Faker::Lorem.sentence, date_issued: "#{Time.now}", other_identifier: ['ABC123'], other_identifier_type: ['local'] }}
    it 'sets other identifers' do
      expect(entry.media_object.other_identifier).to eq([{:source=>"local", :id=>"ABC123"}])
    end
  end

  describe 'notes' do
    let(:entry_fields) {{ title: Faker::Lorem.sentence, date_issued: "#{Time.now}", note: ["This is a test general note"], note_type: ['general'] }}
    it 'sets notes' do
      expect(entry.media_object.note.first).to eq({:note=>"This is a test general note", :type=>"general"})
    end
  end

  describe '#process!' do
    let(:entry_files) { [{ file: File.join(testdir, filename), offset: '00:00:00.500', label: 'Quis quo', date_digitized: '2015-10-30', skip_transcoding: false }] }
    let(:master_file) { entry.media_object.master_files.first }
    before do
      entry.process!
    end

    it 'sets MasterFile details' do
      expect(master_file.title).to eq('Quis quo')
      expect(master_file.poster_offset.to_i).to eq(500)
      expect(master_file.workflow_name).to eq('avalon')
      expect(master_file.absolute_location).to eq(Avalon::FileResolver.new.path_to(master_file.file_location))
      expect(master_file.date_digitized).to eq('2015-10-30T00:00:00Z')
    end

    context 'with caption files' do
      let(:caption_file) { File.join(Rails.root, 'spec/fixtures/dropbox/example_batch_ingest/assets/sheephead_mountain.mov.vtt')}
      let(:caption) {{ :caption_file => caption_file, :caption_label => 'Sheephead Captions', :caption_language => 'English' }}
      let(:entry_files) { [{ file: File.join(testdir, filename), offset: '00:00:00.500', label: 'Quis quo', date_digitized: '2015-10-30', skip_transcoding: false, caption_1: caption }] }

      it 'adds captions to masterfile' do
        expect(master_file.supplemental_file_captions).to be_present
      end
    end
  end

  describe '#attach_datastreams_to_master_file' do
    let(:master_file) { FactoryBot.create(:master_file) }
    let(:filename) { File.join(Rails.root, 'spec/fixtures/dropbox/example_batch_ingest/assets/sheephead_mountain.mov') }
    let(:caption_file) { File.join(Rails.root, 'spec/fixtures/dropbox/example_batch_ingest/assets/sheephead_mountain.mov.vtt')}
    let(:caption) { [{ :caption_file => caption_file, :caption_label => 'Sheephead Captions', :caption_language => 'English' }] }

    before do
      Avalon::Batch::Entry.attach_datastreams_to_master_file(master_file, filename, caption)
    end

    it 'should attach structural metadata' do
      expect(master_file.structuralMetadata.has_content?).to be_truthy
    end
    it 'should attach captions' do
      expect(master_file.supplemental_file_captions).to be_present
    end

    context 'with multiple captions' do
      let(:caption) { [{ :caption_file => caption_file, :caption_label => 'Sheephead Captions', :caption_language => 'english' },
                      { :caption_file => caption_file, :caption_label => 'Second Caption', :caption_language => 'fre' }] }
      it 'should attach all captions to master file' do
        expect(master_file.supplemental_file_captions).to be_present
        expect(master_file.supplemental_file_captions.count).to eq 2
        expect(master_file.supplemental_file_captions[0].label).to eq 'Sheephead Captions'
        expect(master_file.supplemental_file_captions[1].label).to eq 'Second Caption'
        expect(master_file.supplemental_file_captions[0].language).to eq 'eng'
        expect(master_file.supplemental_file_captions[1].language).to eq 'fre'
      end
    end
  end

  describe "#offset_valid?" do
    it {expect(Avalon::Batch::Entry.offset_valid?("33.12345")).to be true}
    it {expect(Avalon::Batch::Entry.offset_valid?("21:33.12345")).to be true}
    it {expect(Avalon::Batch::Entry.offset_valid?("125:21:33.12345")).to be true}
    it {expect(Avalon::Batch::Entry.offset_valid?("63.12345")).to be false}
    it {expect(Avalon::Batch::Entry.offset_valid?("66:33.12345")).to be false}
    it {expect(Avalon::Batch::Entry.offset_valid?(".12345")).to be false}
    it {expect(Avalon::Batch::Entry.offset_valid?(":.12345")).to be false}
    it {expect(Avalon::Batch::Entry.offset_valid?(":33.12345")).to be false}
    it {expect(Avalon::Batch::Entry.offset_valid?(":66:33.12345")).to be false}
    it {expect(Avalon::Batch::Entry.offset_valid?("5:000")).to be false}
    it {expect(Avalon::Batch::Entry.offset_valid?("`5.000")).to be false}
  end

  describe '#to_json' do
    subject { JSON.parse(entry.to_json).symbolize_keys }
    it "returns json" do
      expect(subject[:fields].symbolize_keys).to eq entry.fields
      expect(subject[:files].map(&:symbolize_keys!)).to eq entry.files
      expect(subject[:position]).to eq entry.row
      expect(subject[:user_key]).to eq entry.user_key
      expect(subject[:collection]).to eq entry.collection.id
      expect(subject[:hidden]).to eq entry.opts[:hidden]
      expect(subject[:publish]).to eq entry.opts[:publish]
    end
  end

  describe '#from_json' do
    let(:collection) {FactoryBot.create(:collection)}
    subject { Avalon::Batch::Entry.from_json(entry.to_json) }
    it "initializes a Avalon::Batch::Entry object from a json hash" do
      expect(subject).to be_an Avalon::Batch::Entry
      expect(subject.fields).to eq entry.fields
      expect(subject.files).to eq entry.files
      expect(subject.row).to eq entry.row
      expect(subject.user_key).to eq entry.user_key
      expect(subject.collection.id).to eq entry.collection.id
      expect(subject.opts[:hidden]).to eq entry.opts[:hidden]
      expect(subject.opts[:publish]).to eq entry.opts[:publish]
    end
  end

end
