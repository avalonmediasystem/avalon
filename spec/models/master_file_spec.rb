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

describe MasterFile do
  include ActiveJob::TestHelper

  describe "validations" do
    subject { MasterFile.new }
    it { is_expected.to validate_presence_of(:workflow_name) }
    it { is_expected.to validate_inclusion_of(:workflow_name).in_array(MasterFile::WORKFLOWS) }
    xit { is_expected.to validate_presence_of(:file_format) }
    xit { is_expected.to validate_exclusion_of(:file_format).in_array(['Unknown']).with_message("The file was not recognized as audio or video.") }
    it { is_expected.to validate_inclusion_of(:date_digitized).in_array([nil, '2016-04-07T15:05:01-05:00', '2016-04-07']).with_message(//) }
    it { is_expected.to validate_exclusion_of(:date_digitized).in_array(["","2016-14-99","Blergh"]).with_message(//) }
  end

  describe "locations" do
    subject {
      mf = MasterFile.new
      mf.file_location = '/foo/bar/baz/quux.mp4'
      mf.save
      mf
    }

    it "should know where its (local) master_file is" do
      expect(subject.file_location).to eq '/foo/bar/baz/quux.mp4'
      expect(subject.absolute_location).to eq 'file:///foo/bar/baz/quux.mp4'
    end

    it "should know where its (Samba remote) master_file is" do
      allow_any_instance_of(Avalon::FileResolver).to receive(:mounts) {
        ["//user@some.server.at.an.example.edu/stuff on /foo/bar (smbfs, nodev, nosuid, mounted by user)"]
      }
      expect(subject.absolute_location).to eq 'smb://some.server.at.an.example.edu/stuff/baz/quux.mp4'
    end

    it "should know where its (CIFS remote) master_file is" do
      allow_any_instance_of(Avalon::FileResolver).to receive(:mounts) {
        ["//user@some.server.at.an.example.edu/stuff on /foo/bar (cifs, nodev, nosuid, mounted by user)"]
      }
      expect(subject.absolute_location).to eq 'cifs://some.server.at.an.example.edu/stuff/baz/quux.mp4'
    end

    it "should know where its (NFS remote) master_file is" do
      allow_any_instance_of(Avalon::FileResolver).to receive(:mounts) {
        ["some.server.at.an.example.edu:/stuff on /foo/bar (nfs, nodev, nosuid, mounted by user)"]
      }
      expect(subject.absolute_location).to eq 'nfs://some.server.at.an.example.edu/stuff/baz/quux.mp4'
    end

    it "should follow the file to a new location" do
      subject.file_location = "/tmp/baz/quux.mp4"
      expect(subject.absolute_location).to eq 'file:///tmp/baz/quux.mp4'
    end

    it "should accept configurable overrides" do
      allow_any_instance_of(Avalon::FileResolver).to receive(:overrides) {
        { '/foo/bar/' => 'http://repository.example.edu/foothings/' }
      }
      expect(subject.absolute_location).to eq 'http://repository.example.edu/foothings/baz/quux.mp4'
    end

    it "should accept an empty file location" do
      subject.file_location = ""
      expect(subject.absolute_location).to be_empty
    end

    it "should accept a nil file location" do
      subject.file_location = nil
      expect(subject.absolute_location).to be_nil
    end
  end

  describe "master_files=" do
    let(:derivative) {Derivative.create}
    let(:master_file) {FactoryBot.create(:master_file)}
    it "should set hasDerivation relationships on self" do
      master_file.derivatives += [derivative]
      expect(derivative.association_cache).to have_key(:master_file)
      expect(derivative.association_cache[:master_file].target.id).to eq(master_file.id)
    end
  end

  describe '#finished_processing?' do
    describe 'classifying statuses' do
      let(:master_file){ MasterFile.new }
      it 'returns true for cancelled' do
        allow(master_file).to receive(:status_code).and_return('CANCELLED')
        expect(master_file.finished_processing?).to be true
      end
      it 'returns true for succeeded' do
        allow(master_file).to receive(:status_code).and_return('COMPLETED')
        expect(master_file.finished_processing?).to be true
      end
      it 'returns true for failed' do
        allow(master_file).to receive(:status_code).and_return('FAILED')
        expect(master_file.finished_processing?).to be true
      end
    end
  end

  describe '#process' do
    let(:master_file) { FactoryBot.create(:master_file, :not_processing) }

    around(:example) do |example|
      perform_enqueued_jobs { example.run }
    end

    it 'creates an encode' do
      expect(master_file.encoder_class).to receive(:create).with("file://" + Addressable::URI.escape(master_file.file_location), { master_file_id: master_file.id, preset: master_file.workflow_name, headers: nil })
      master_file.process
    end

    describe 'already processing' do
      let(:master_file) { FactoryBot.create(:master_file) }
      it 'should not start an ActiveEncode workflow' do
        expect(master_file.encoder_class).not_to receive(:create)
        expect{ master_file.process }.to raise_error(RuntimeError)
      end
    end

    context 'pass through' do
      let(:master_file) { FactoryBot.create(:master_file, :not_processing, workflow_name: 'pass_through') }

      context 'with multiple files' do
	let(:low_file) { "spec/fixtures/videoshort.low.mp4" }
	let(:medium_file) { "spec/fixtures/videoshort.medium.mp4" }
	let(:high_file) { "spec/fixtures/videoshort.high.mp4" }
        let(:outputs_hash) do
          [
            { label: 'low', url: FileLocator.new(low_file).uri.to_s },
            { label: 'medium', url: FileLocator.new(medium_file).uri.to_s },
            { label: 'high', url: FileLocator.new(high_file).uri.to_s }
          ]
        end
        let(:files) do
          {
            "quality-low" => FileLocator.new(low_file).attachment,
            "quality-medium" => FileLocator.new(medium_file).attachment,
            "quality-high" => FileLocator.new(high_file).attachment
          }
        end

        it 'creates an encode' do
	  expect(master_file.encoder_class).to receive(:create).with("file://" + Rails.root.join(high_file).to_path, { outputs: outputs_hash, master_file_id: master_file.id, preset: master_file.workflow_name })
	  master_file.process(files)
        end
      end

      context 'with single file' do
        let(:input_url) { FileLocator.new(master_file.file_location).uri.to_s }
        let(:outputs_hash) { [{ label: 'high', url: input_url }] }

        it 'creates an encode' do
          expect(master_file.encoder_class).to receive(:create).with(input_url, { outputs: outputs_hash, master_file_id: master_file.id, preset: master_file.workflow_name })
	  master_file.process
        end
      end
    end
  end

  describe "delete" do
    subject(:master_file) { FactoryBot.create(:master_file) }

    it "should delete (VOV-1805)" do
      mf = FactoryBot.create(:master_file)
      expect { mf.delete }.to change { MasterFile.all.count }.by(-1)
    end

    it "should delete with a nil parent (VOV-1357)" do
      master_file.media_object = nil
      master_file.save
      expect { master_file.delete }.to change { MasterFile.all.count }.by(-1)
    end
  end

  describe "image_offset" do
    subject(:master_file) {FactoryBot.create(:master_file, duration: (rand(21600000)+60000).to_s )}

    describe "milliseconds" do
      it "should accept a value" do
        offset = master_file.duration.to_i / 2
        master_file.poster_offset = offset
        expect(master_file.poster_offset).to eq(offset)
        expect(master_file).to be_valid
      end

      it "should complain if value < 0" do
        master_file.poster_offset = -1
        expect(master_file).not_to be_valid
        expect(master_file.errors[:poster_offset].first).to eq("must be between 0 and #{master_file.duration}")
      end

      it "should complain if value > duration" do
        offset = master_file.duration.to_i + rand(32514) + 500
        master_file.poster_offset = offset
        expect(master_file).not_to be_valid
        expect(master_file.errors[:poster_offset].first).to eq("must be between 0 and #{master_file.duration}")
      end
    end

    describe "hh:mm:ss.sss" do
      it "should accept a value" do
        offset = master_file.duration.to_i / 2
        master_file.poster_offset = offset.to_hms
        expect(master_file.poster_offset).to eq(offset)
        expect(master_file).to be_valid
      end

      it "should complain if value > duration" do
        offset = master_file.duration.to_i + rand(32514) + 500
        master_file.poster_offset = offset.to_hms
        expect(master_file).not_to be_valid
        expect(master_file.errors[:poster_offset].first).to eq("must be between 0 and #{master_file.duration}")
      end
    end

    describe "update images" do
      before do
        MasterFile.set_callback(:save, :after, :update_stills_from_offset!)
      end
      after do
        MasterFile.skip_callback(:save, :after, :update_stills_from_offset!)
      end
      it "should update on save" do
        master_file.poster_offset = 12345
        master_file.save
        expect(ExtractStillJob).to have_been_enqueued.with(master_file.id, { type: 'both', offset: 12345, headers: nil })
      end
    end
  end

  describe "#set_workflow" do
    let (:master_file) {MasterFile.new}
    describe "custom workflow" do

      describe "video" do
        it "should not use the skipped transcoding workflow" do
          master_file.file_format = 'Moving image'
          master_file.set_workflow
          expect(master_file.workflow_name).to eq('avalon')
        end
        it "should use the skipped transcoding workflow for video" do
          master_file.file_format = 'Moving image'
          master_file.set_workflow('skip_transcoding')
          expect(master_file.workflow_name).to eq('pass_through')
        end
      end

      describe "audio" do
        it "should not use the skipped transcoding workflow" do
          master_file.file_format = 'Sound'
          master_file.set_workflow
          expect(master_file.workflow_name).to eq('fullaudio')
        end
        it "should use the skipped transcoding workflow for video" do
          master_file.file_format = 'Sound'
          master_file.set_workflow('skip_transcoding')
          expect(master_file.workflow_name).to eq('pass_through')
        end
      end
    end
    describe "video" do
      it "should use the avalon workflow" do
        master_file.file_format = 'Moving image'
        master_file.set_workflow
        expect(master_file.workflow_name).to eq('avalon')
      end
    end
    describe "audio" do
      it "should use the fullaudio workflow" do
        master_file.file_format = 'Sound'
        master_file.set_workflow
        expect(master_file.workflow_name).to eq('fullaudio')
      end
    end
    describe "unknown format" do
      it "should set workflow_name to nil" do
        master_file.file_format = 'Unknown'
        master_file.set_workflow
        expect(master_file.workflow_name).to eq(nil)
      end
    end
  end

  describe '#setContent' do
    describe "multiple files for pre-transcoded derivatives" do
      let(:filename_high)    { File.expand_path('../../fixtures/videoshort.high.mp4',__FILE__) }
      let(:filename_medium)    { File.expand_path('../../fixtures/videoshort.medium.mp4',__FILE__) }
      let(:filename_low)    { File.expand_path('../../fixtures/videoshort.low.mp4',__FILE__) }
      let(:derivative_hash) {{'quality-low' => File.new(filename_low), 'quality-medium' => File.new(filename_medium), 'quality-high' => File.new(filename_high)}}

      describe "quality-high exists" do
        it "it should set the correct file location and size" do
          master_file = FactoryBot.create(:master_file)
          master_file.setContent(derivative_hash)
          expect(master_file.file_location).to eq(filename_high)
          expect(master_file.file_size).to eq("199160")
        end
      end
      describe "quality-high does not exist" do
        it "should set the correct file location and size" do
          master_file = FactoryBot.create(:master_file)
          master_file.setContent(derivative_hash.except("quality-high"))
          expect(master_file.file_location).to eq(filename_medium)
          expect(master_file.file_size).to eq("199160")
        end
      end

    end

    describe "web-uploaded file" do
      let(:fixture)    { File.expand_path('../../fixtures/videoshort.mp4',__FILE__) }
      let(:original)   { File.basename(fixture) }
      let(:tempfile)   { Tempfile.new('foo') }
      let(:media_path) { File.expand_path("../../master_files-#{SecureRandom.uuid}",__FILE__)}
      let(:dropbox_path) { File.expand_path("../../collection-#{SecureRandom.uuid}",__FILE__)}
      let(:upload)     { ActionDispatch::Http::UploadedFile.new :tempfile => tempfile, :filename => original, :type => 'video/mp4' }
      let(:media_object) { MediaObject.new }
      let(:collection) { Admin::Collection.new }
      subject {
        mf = MasterFile.new
        mf.media_object = media_object
        mf.setContent(upload, dropbox_dir: collection.dropbox_absolute_path)
        mf
      }

      before(:each) do
        @old_media_path = Settings.encoding.working_file_path
        FileUtils.mkdir_p media_path
        FileUtils.cp fixture, tempfile
        allow(media_object).to receive(:collection).and_return(collection)
        FileUtils.mkdir_p dropbox_path
        allow(collection).to receive(:dropbox_absolute_path).and_return(File.absolute_path(dropbox_path))
      end

      after(:each) do
        Settings.encoding.working_file_path = @old_media_path
        File.unlink subject.file_location
        FileUtils.rm_rf media_path
        FileUtils.rm_rf dropbox_path
      end

      it "should move an uploaded file into the root of the collection's dropbox" do
        Settings.encoding.working_file_path = nil
        expect(subject.file_location).to eq(File.realpath(File.join(collection.dropbox_absolute_path,original)))
      end

      it "should copy an uploaded file to the media path" do
        Settings.encoding.working_file_path = media_path
        expect(File.fnmatch("#{media_path}/*/#{original}", subject.working_file_path.first)).to be true
      end

      context "when file with same name already exists in the collection's dropbox" do
        let(:duplicate) { "videoshort-1.mp4" }

        before do
          FileUtils.cp fixture, File.join(collection.dropbox_absolute_path, original)
        end

        it "appends a numerical suffix" do
          Settings.encoding.working_file_path = nil
          expect(subject.file_location).to eq(File.realpath(File.join(collection.dropbox_absolute_path,duplicate)))
        end
      end
    end

    context "server-side dropbox" do
      let(:fixture)    { File.expand_path('../../fixtures/videoshort.mp4',__FILE__) }
      let(:original)   { File.basename(fixture) }
      let(:dropbox_file_path) { File.join(dropbox_path, 'nested-dir', original)}
      let(:media_path) { File.expand_path("../../master_files-#{SecureRandom.uuid}",__FILE__)}
      let(:dropbox_path) { File.expand_path("../../collection-#{SecureRandom.uuid}",__FILE__)}
      let(:media_object) { MediaObject.new }
      let(:collection) { Admin::Collection.new }
      subject {
        mf = MasterFile.new
        mf.media_object = media_object
        mf.setContent(File.new(dropbox_file_path), dropbox_dir: collection.dropbox_absolute_path)
        mf
      }

      before(:each) do
        @old_media_path = Settings.encoding.working_file_path
        FileUtils.mkdir_p dropbox_path
        FileUtils.mkdir_p media_path
        FileUtils.mkdir_p File.dirname(dropbox_file_path)
        FileUtils.cp fixture, dropbox_file_path
        allow(media_object).to receive(:collection).and_return(collection)
        allow(collection).to receive(:dropbox_absolute_path).and_return(File.absolute_path(dropbox_path))
      end

      after(:each) do
        Settings.encoding.working_file_path = @old_media_path
        File.unlink subject.file_location
        FileUtils.rm_rf media_path
        FileUtils.rm_rf dropbox_path
      end

      it "should not move a file in a subdirectory of the collection's dropbox" do
        Settings.encoding.working_file_path = nil
        expect(subject.file_location).to eq dropbox_file_path
        expect(File.exist?(dropbox_file_path)).to eq true
        expect(File.exist?(File.join(collection.dropbox_absolute_path,original))).to eq false
      end

      it "should copy an uploaded file to the media path" do
        Settings.encoding.working_file_path = media_path
        expect(File.fnmatch("#{media_path}/*/#{original}", subject.working_file_path.first)).to be true
      end
    end

    context "google drive" do
      let(:file) { Addressable::URI.parse("https://www.googleapis.com/drive/v3/files/1QFnOuYM7o7wUn-k8hwfgGYPuM6v6c_Ct?alt=media") }
      let(:file_name) { "sample.mp4" }
      let(:file_size) { 12345 }
      let(:auth_header) { {"Authorization"=>"Bearer ya29.a0AfH6SMC6vSj4D6po1aDxAr6JmY92azh3lxevSuPKxf9QPPSKmMzqbZvI7B3oIACqqMVono1P0XD2F1Jl_rkayoI6JGz-P2cpg44-55oJFcWychAvUliWeRKf1cifMo9JF10YmXxhIfrG5mu7Ahy9FZpudN92p2JhvTI"} }

      subject { MasterFile.new }

      it "should set the right properties" do
        allow(subject).to receive(:reloadTechnicalMetadata!).and_return(nil)
        subject.setContent(file, file_name: file_name, file_size: file_size, auth_header: auth_header)
        expect(subject.file_location).to eq(file.to_s)
        expect(subject.file_size).to eq(file_size)
        expect(subject.title).to eq(file_name)
        expect(subject.instance_variable_get(:@auth_header)).to eq(auth_header)
      end
    end
  end

  describe "#encoder_class" do
    subject { FactoryBot.build(:master_file) }

    it "should default to WatchedEncode" do
      expect(subject.encoder_class).to eq(WatchedEncode)
    end

    it "should infer the class from a workflow name" do
      stub_const("WorkflowEncode", Class.new(ActiveEncode::Base))
      subject.workflow_name = 'workflow'
      expect(subject.encoder_class).to eq(WorkflowEncode)
    end

    it "should fall back to Watched when a workflow class can't be resolved" do
      subject.workflow_name = 'nonexistent_workflow_encoder'
      expect(subject.encoder_class).to eq(WatchedEncode)
    end

    it "should fall back to Watched when a workflow class can't be resolved" do
      subject.encoder_classname = 'my-awesomeEncode'
      expect(subject.encoder_class).to eq(WatchedEncode)
    end

    it "should resolve an explicitly named encoder class" do
      stub_const("EncoderModule::MyEncoder", Class.new(ActiveEncode::Base))
      subject.encoder_classname = 'EncoderModule::MyEncoder'
      expect(subject.encoder_class).to eq(EncoderModule::MyEncoder)
    end

    it "should fall back to WatchedEncode when an encoder class can't be resolved" do
      subject.encoder_classname = 'EncoderModule::NonexistentEncoder'
      expect(subject.encoder_class).to eq(WatchedEncode)
    end

    it "should correctly set the encoder classname from the encoder" do
      stub_const("EncoderModule::MyEncoder", Class.new(ActiveEncode::Base))
      subject.encoder_class = EncoderModule::MyEncoder
      expect(subject.encoder_classname).to eq('EncoderModule::MyEncoder')
    end

    it "should reject an invalid encoder class" do
      expect { subject.encoder_class = Object }.to raise_error(ArgumentError)
    end

    context 'with an encoder class named after the engine adapter' do
      it "should find the encoder class" do
        stub_const("TestEncode", Class.new(ActiveEncode::Base))
        expect(Settings.encoding.engine_adapter).to eq "test"
        expect(subject.encoder_class).to eq(TestEncode)
      end
    end
  end

  describe "#embed_title" do
    context "with structure" do
      subject { FactoryBot.create( :master_file, :with_structure, { media_object: FactoryBot.create( :media_object, { title: "test" })})}

      it "should favor the structure item label" do
        expect( subject.embed_title ).to eq( "test - CD 1" )
      end
    end

    context "without structure" do
      subject { FactoryBot.create( :master_file, { media_object: FactoryBot.create( :media_object, { title: "test" })})}

      it "should have an appropriate title for the embed code with a label" do
        subject.title = "test"
        expect( subject.embed_title ).to eq( "test - test" )
      end

      it "should have an appropriate title for the embed code with no label (only one section)" do
        expect( subject.embed_title ).to eq( "test" )
      end

      it 'should have an appropriate title for the embed code with no label (more than 1 section)' do
        allow(subject.media_object).to receive(:ordered_master_files).and_return([subject,subject])
        allow(subject.media_object).to receive(:master_file_ids).and_return([subject.id,subject.id])
        expect( subject.embed_title ).to eq( 'test - video.mp4' )
      end

      it "should have an appropriate title for the embed code with no label or file_location" do
        subject.file_location = nil
        expect( subject.embed_title ).to eq( "test" )
      end
    end
  end

  describe "#update_ingest_batch" do
    let(:media_object) {FactoryBot.create(:media_object)}
    let!(:ingest_batch) {IngestBatch.create(media_object_ids: [media_object.id], email: Faker::Internet.email)}
    let(:master_file) {FactoryBot.create( :master_file, :completed_processing, media_object: media_object)}
    it 'should send email when ingest batch is finished processing' do
      master_file.send(:update_ingest_batch)
      expect(ingest_batch.reload.email_sent?).to be true
    end
  end

  describe '#update_progress_on_success!' do
    subject(:master_file) { FactoryBot.create(:master_file) }
    let(:encode) { double("encode", :output => []) }
    before do
      allow(master_file).to receive(:update_ingest_batch).and_return(true)
    end

    it 'should set the digitized date' do
      master_file.update_progress_on_success!(encode)
      master_file.reload
      expect(master_file.date_digitized).to_not be_empty
    end

  end

  describe "#structural_metadata_labels" do
    subject(:master_file) { FactoryBot.create(:master_file, :with_structure) }
    it 'should return correct list of labels' do
      expect(master_file.structural_metadata_labels.first).to eq 'CD 1'
    end
  end

  describe 'rdf formatted information' do
    subject(:video_master_file) { FactoryBot.create(:master_file) }
    subject(:sound_master_file) { FactoryBot.create(:master_file, file_format: 'Sound') }
    describe 'type' do
      it 'returns dctypes:MovingImage when the file is a video' do
        expect(video_master_file.rdf_type).to match('dctypes:MovingImage')
      end
      it 'return dctypes:Sound when the file is audio' do
        expect(sound_master_file.rdf_type).to match('dctypes:Sound')
      end
    end
    describe 'uri' do
      it 'returns a uri for a sound master file' do
        expect(sound_master_file.rdf_uri.class).to eq(String)
        expect { Addressable::URI.parse(sound_master_file.rdf_uri) }.not_to raise_error
      end
      it 'returns a uri for a video master file' do
        expect(video_master_file.rdf_uri.class).to eq(String)
        expect { Addressable::URI.parse(video_master_file.rdf_uri) }.not_to raise_error
      end
    end
  end

  describe '#post_processing_move_filename' do
    let(:id) { 'avalon:12345' }
    let(:id_prefix) { 'avalon_12345' }
    let(:path) { '/path/to/video.mp4' }
    it 'prepends the id' do
      expect(MasterFile.post_processing_move_filename(path, id: id).starts_with?(id_prefix)).to be_truthy
    end
    it 'returns a filename' do
      expect(File.dirname(MasterFile.post_processing_move_filename(path, id: id))).to eq('.')
    end
    it 'does not prepend the id if already present' do
      path = '/path/to/avalon_12345-video.mp4'
      expect(MasterFile.post_processing_move_filename(path, id: id).include?(id_prefix + '-' + id_prefix)).to be_falsey
    end
    context 'path contains spaces' do
      path = '/path/to/video file.mp4'
      it 'removes spaces' do
        expect(MasterFile.post_processing_move_filename(path, id: id)).not_to include(' ')
      end
    end
  end

  context 'with a working directory' do
    subject(:master_file) { FactoryBot.create(:master_file) }
    let(:working_dir) { Dir.mktmpdir }
    before do
      Settings.encoding.working_file_path = working_dir
    end

    after do
      Settings.encoding.working_file_path = nil
    end
    describe 'post_processing_working_directory_file_management' do
      it 'enqueues the working directory cleanup job' do
        master_file.send(:post_processing_file_management)
        expect(CleanupWorkingFileJob).to have_been_enqueued.with(master_file.id, master_file.working_file_path)
      end
    end
    describe '#working_file_path' do
      it 'returns blank when the working directory is invalid' do
        expect(master_file.working_file_path).to be_blank
      end

      it 'returns a path when the working directory is valid' do
        file = File.new(Rails.root.join('spec', 'fixtures', 'videoshort.mp4'))
        master_file.setContent(file)
        expect(master_file.working_file_path.first).to include(Settings.encoding.working_file_path)
      end
    end
  end

  describe "waveform generation" do
    subject(:master_file) { FactoryBot.create(:master_file) }

    it 'runs the waveform job' do
      expect(WaveformJob).to receive(:perform_later).with(master_file.id)
      master_file.send(:generate_waveform)
    end
  end

  describe '#extract_frame' do
    subject(:video_master_file) { FactoryBot.create(:master_file, :with_media_object, :with_derivative, display_aspect_ratio: '1') }
    before do
      allow(video_master_file).to receive(:find_frame_source).and_return({source: video_master_file.file_location, offset: 1, master: false})
    end
    it "raises an exception when ffmpeg doesn't extract anything" do
      expect {video_master_file.send(:extract_frame, {size: '160x120', offset: 1})}.to raise_error
    end
  end

  describe 'find_frame_source' do
    context 'when master_file has been deleted' do
      subject(:video_master_file) { FactoryBot.create(:master_file, :with_media_object, :with_derivative, display_aspect_ratio: '1', file_location: '') }
      let(:source) { video_master_file.send(:find_frame_source) }

      context 'when derivatives are accessible' do
        let(:high_derivative_locator) { FileLocator.new(video_master_file.derivatives.where(quality_ssi: 'high').first.absolute_location) }

        it 'uses high derivative' do
          expect(File).to receive(:exist?).with(high_derivative_locator.location).and_return(true)
          expect(source[:source]).to eq high_derivative_locator.location
          expect(source[:non_temp_file]).to eq true
        end
      end

      context 'when derivatives are not accessible' do
        let(:high_derivative_locator) { FileLocator.new(video_master_file.derivatives.where(quality_ssi: 'high').first.absolute_location) }
        let(:hls_temp_file) { "/tmp/temp_segment.ts" }

        it 'falls back to HLS' do
          expect(video_master_file).to receive(:create_frame_source_hls_temp_file).and_return(hls_temp_file)
          expect(File).to receive(:exist?).with(high_derivative_locator.location).and_return(false)
          expect(source[:source]).to eq '/tmp/temp_segment.ts'
          expect(source[:non_temp_file]).to eq false
        end
      end
    end
  end

  describe '#ffmpeg_frame_options' do
    subject { FactoryBot.create(:master_file, :with_media_object, :with_derivative, display_aspect_ratio: '1') }

    it "return the correct options" do
      expect(subject.send(:ffmpeg_frame_options, "/tmp/test.mp4", "/tmp/test.jpg", 2000, 360, 240, true, { test_header: "header content" })).to eq(
        ["-headers", "test_header: header content\r\n", "-ss", "2.0", "-i", "/tmp/test.mp4", "-s", "360x240", "-vframes", "1", "-aspect", "1", "-q:v", "4", "-y", "/tmp/test.jpg"]
      )
    end
  end

  describe 'poster' do
    let(:master_file) { FactoryBot.create(:master_file) }
    it 'sets original_name to default value' do
      expect(master_file.poster.original_name).to eq 'poster.jpg'
    end
  end

  describe 'thumbnail' do
    let(:master_file) { FactoryBot.create(:master_file) }
    it 'sets original_name to default value' do
      expect(master_file.thumbnail.original_name).to eq 'thumbnail.jpg'
    end
  end

  describe 'structuralMetadata' do
    let(:master_file) { FactoryBot.create(:master_file) }
    it 'sets original_name to default value' do
      expect(master_file.structuralMetadata.original_name).to eq 'structuralMetadata.xml'
    end
  end

  describe 'captions' do
    let(:master_file) { FactoryBot.create(:master_file) }
    it 'has a caption' do
      expect(master_file.captions).to be_kind_of IndexedFile
    end
  end

  describe 'supplemental_file_captions' do
    let(:master_file) { FactoryBot.create(:master_file) }
    it 'has a caption' do
      expect(master_file.supplemental_file_captions).to all(be_kind_of(SupplementalFile))
    end
  end

  describe 'waveforms' do
    let(:master_file) { FactoryBot.create(:master_file) }
    it 'sets original_name to default value' do
      expect(master_file.waveform).to be_kind_of IndexedFile
      expect(master_file.waveform.original_name).to eq 'waveform.json'
    end
  end

  describe 'update_parent!' do
    it 'does not error if the master file has no parent' do
      expect { MasterFile.new.send(:update_parent!) }.not_to raise_error
    end
  end

  describe 'stop_processing!' do
    let(:master_file) { FactoryBot.build(:master_file) }
    before do
      allow(ActiveEncode::Base).to receive(:find).and_return(nil)
    end
    it 'does not error if the master file has no encode' do
      expect { master_file.send(:stop_processing!) }.not_to raise_error
    end
  end

  describe 'hls_streams' do
    let(:master_file) { FactoryBot.create(:master_file) }
    let(:streams) do
      [{:format=>"video",
        :mimetype=>nil,
        :quality=>"auto",
        :url=>"http://test.host/master_files/#{master_file.id}/auto.m3u8"},
      {:bitrate=>4163842,
        :format=>"video",
        :mimetype=>nil,
        :quality=>"high",
        :url=>
         "http://localhost:3000/streams/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4.m3u8"},
      {:bitrate=>4163842,
        :format=>"video",
        :mimetype=>nil,
        :quality=>"medium",
        :url=>
         "http://localhost:3000/streams/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4.m3u8"}]
    end
    before do
      master_file.derivatives += [FactoryBot.create(:derivative, quality: 'high'), FactoryBot.create(:derivative, quality: 'medium')]
      master_file.save
    end

    it 'returns a sorted hash of hls streams' do
      expect(master_file.hls_streams).to eq streams
    end
  end

  describe 'media_object=' do
    let!(:master_file) { FactoryBot.create(:master_file, :with_media_object) }
    let!(:media_object1) { master_file.media_object }
    let!(:media_object2) { FactoryBot.create(:media_object) }

    it 'sets a new media object as its parent' do
      master_file.media_object = media_object2
      expect(media_object1.reload.master_file_ids).not_to include master_file.id
      expect(media_object1.reload.ordered_master_file_ids).not_to include master_file.id
      expect(media_object2.reload.master_file_ids).to include master_file.id
      expect(media_object2.reload.ordered_master_file_ids).to include master_file.id
    end
  end

  describe 'update_progress_on_success!' do
    let(:master_file) { FactoryBot.build(:master_file) }
    let(:encode_succeeded) { FactoryBot.build(:encode, :succeeded) }

    it 'calls update_derivatives' do
      expect(master_file).to receive(:update_derivatives).with(array_including(hash_including(label: 'quality-high')))
      expect(master_file).to receive(:run_hook).with(:after_transcoding)
      master_file.update_progress_on_success!(encode_succeeded)
    end
  end

  describe 'update_derivatives' do
    let(:master_file) { FactoryBot.create(:master_file) }
    let(:new_derivative) { FactoryBot.build(:derivative) }
    let(:outputs) { [{ label: 'high' }]}

    before do
      allow(Derivative).to receive(:from_output).and_return(new_derivative)
    end

    it 'creates a new derivative' do
      expect { master_file.update_derivatives(outputs) }.to change { Derivative.count }.by(1)
    end

    context 'overwriting' do
      let!(:master_file_with_derivative) { FactoryBot.create(:master_file, :with_derivative) }
      let(:existing_derivative) { master_file_with_derivative.derivatives.first }

      it 'overwrites existing derivatives' do
        expect { master_file_with_derivative.update_derivatives(outputs) }.not_to change { Derivative.count }
        expect(ActiveFedora::Base.exists?(existing_derivative)).to eq false
        expect(master_file_with_derivative.reload.derivative_ids).not_to include(existing_derivative.id)
        expect(master_file_with_derivative.reload.derivative_ids).not_to be_empty
      end
    end
  end

  describe '#to_ingest_api_hash' do
    let(:master_file) { FactoryBot.build(:master_file, identifier: ['ABCDE12345']) }

    context 'remove_identifiers parameter' do
      it 'removes identifiers if parameter is true' do
        expect(master_file.identifier).not_to be_empty
        expect(master_file.to_ingest_api_hash(false, remove_identifiers: true)[:other_identifier]).to be_empty
      end

      it 'does not remove identifiers if parameter is not present' do
        expect(master_file.identifier).not_to be_empty
        expect(master_file.to_ingest_api_hash(false, remove_identifiers: false)[:other_identifier]).not_to be_empty
        expect(master_file.to_ingest_api_hash(false)[:other_identifier]).not_to be_empty
      end
    end
  end

  it_behaves_like "an object that has supplemental files"

  describe 'has_audio?' do

    context 'without derivative' do
      let(:master_file) { FactoryBot.build(:master_file) }

      it 'returns false' do
        expect(master_file.has_audio?).to eq false
      end
    end

    context 'with derivative' do
      let(:master_file) { FactoryBot.build(:master_file, derivatives: [derivative]) }

      context 'with audio track' do
        let(:derivative) { FactoryBot.build(:derivative, audio_codec: 'aac') }

        it 'returns true' do
          expect(master_file.has_audio?).to eq true
        end
      end

      context 'without audio track' do
        let(:derivative) { FactoryBot.build(:derivative, audio_codec: nil) }

        it 'returns false' do
          expect(master_file.has_audio?).to eq false
        end
      end
    end
  end

  describe 'indexing' do
    let(:master_file) { FactoryBot.build(:master_file, :with_media_object) }

    before do
      # Force creation of master_file and then clear queue of byproduct jobs
      master_file
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      ActiveJob::Uniqueness.unlock!
    end

    it 'enqueues indexing of parent media object' do
      master_file.update_index
      expect(MediaObjectIndexingJob).to have_been_enqueued.with(master_file.media_object.id)
    end
  end
end
