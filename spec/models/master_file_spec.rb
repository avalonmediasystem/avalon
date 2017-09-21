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

describe MasterFile do

  describe "validations" do
    subject {MasterFile.new}
    it {is_expected.to validate_presence_of(:workflow_name)}
    it {is_expected.to validate_inclusion_of(:workflow_name).in_array(MasterFile::WORKFLOWS)}
    xit {is_expected.to validate_presence_of(:file_format)}
    xit {is_expected.to validate_exclusion_of(:file_format).in_array(['Unknown']).with_message("The file was not recognized as audio or video.")}
    it {is_expected.to validate_inclusion_of(:date_digitized).in_array([nil, '2016-04-07T15:05:01-05:00', '2016-04-07'])}
    it {is_expected.to validate_exclusion_of(:date_digitized).in_array(["","2016-14-99","Blergh"]).with_message(//)}
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
    let(:master_file) {FactoryGirl.create(:master_file)}
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
        master_file.status_code = 'CANCELLED'
        expect(master_file.finished_processing?).to be true
      end
      it 'returns true for succeeded' do
        master_file.status_code = 'COMPLETED'
        expect(master_file.finished_processing?).to be true
      end
      it 'returns true for failed' do
        master_file.status_code = 'FAILED'
        expect(master_file.finished_processing?).to be true
      end
    end
  end

  describe '#process' do
    let!(:master_file) { FactoryGirl.create(:master_file) }
    # let(:encode_job) { ActiveEncodeJob::Create.new(master_file.id, nil, {}) }
    before do
      ActiveJob::Base.queue_adapter = :test
      # allow(ActiveEncodeJob::Create).to receive(:new).and_return(encode_job)
      # allow(encode_job).to receive(:perform)
    end
    it 'starts an ActiveEncode workflow' do
      master_file.process
      expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, "file://" + URI.escape(master_file.file_location), {preset: master_file.workflow_name})
      # expect(encode_job).to have_received(:perform)
    end
    describe 'already processing' do
      before do
        master_file.status_code = 'RUNNING'
      end
      it 'should not start an ActiveEncode workflow' do
        expect{master_file.process}.to raise_error(RuntimeError)
        expect(ActiveEncodeJob::Create).not_to have_been_enqueued
        # expect(encode_job).not_to have_received(:perform)
      end
    end
  end

  describe "delete" do
    subject(:master_file) { FactoryGirl.create(:master_file) }

    it "should delete (VOV-1805)" do
      mf = FactoryGirl.create(:master_file)
      expect { mf.delete }.to change { MasterFile.all.count }.by(-1)
    end

    it "should delete with a nil parent (VOV-1357)" do
      master_file.media_object = nil
      master_file.save
      expect { master_file.delete }.to change { MasterFile.all.count }.by(-1)
    end
  end

  describe "image_offset" do
    subject(:master_file) {FactoryGirl.create(:master_file, duration: (rand(21600000)+60000).to_s )}

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
        ActiveJob::Base.queue_adapter = :test
        MasterFile.set_callback(:save, :after, :update_stills_from_offset!)
      end
      after do
        ActiveJob::Base.queue_adapter = :inline
        MasterFile.skip_callback(:save, :after, :update_stills_from_offset!)
      end
      it "should update on save" do
        master_file.poster_offset = 12345
        master_file.save
        expect(ExtractStillJob).to have_been_enqueued.with(master_file.id,{type:'both',offset:12345})
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
          expect(master_file.workflow_name).to eq('avalon-skip-transcoding')
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
          expect(master_file.workflow_name).to eq('avalon-skip-transcoding-audio')
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
          master_file = FactoryGirl.create(:master_file)
          master_file.setContent(derivative_hash)
          expect(master_file.file_location).to eq(filename_high)
          expect(master_file.file_size).to eq("199160")
        end
      end
      describe "quality-high does not exist" do
        it "should set the correct file location and size" do
          master_file = FactoryGirl.create(:master_file)
          master_file.setContent(derivative_hash.except("quality-high"))
          expect(master_file.file_location).to eq(filename_medium)
          expect(master_file.file_size).to eq("199160")
        end
      end

    end

    describe "single uploaded file" do
      describe "uploaded file" do
        let(:fixture)    { File.expand_path('../../fixtures/videoshort.mp4',__FILE__) }
        let(:original)   { File.basename(fixture) }
        let(:tempfile)   { Tempfile.new('foo') }
        let(:media_path) { File.expand_path("../../master_files-#{SecureRandom.uuid}",__FILE__)}
        let(:upload)     { ActionDispatch::Http::UploadedFile.new :tempfile => tempfile, :filename => original, :type => 'video/mp4' }
        subject {
          mf = MasterFile.new
          mf.setContent(upload)
          mf
        }

        before(:each) do
          @old_media_path = Avalon::Configuration.lookup('matterhorn.media_path')
          FileUtils.mkdir_p media_path
          FileUtils.cp fixture, tempfile
        end

        after(:each) do
          Avalon::Configuration['matterhorn']['media_path'] = @old_media_path
          File.unlink subject.file_location
          FileUtils.rm_rf media_path
        end

        it "should rename an uploaded file in place" do
          Avalon::Configuration['matterhorn'].delete('media_path')
          expect(subject.file_location).to eq(File.realpath(File.join(File.dirname(tempfile),original)))
        end

        it "should copy an uploaded file to the media path" do
          Avalon::Configuration['matterhorn']['media_path'] = media_path
          expect(subject.file_location).to eq(File.join(media_path,original))
        end
      end
    end
  end

  describe "#encoder_class" do
    subject { FactoryGirl.create(:master_file) }

    before :all do
      class WorkflowEncoder < ActiveEncode::Base
      end

      module EncoderModule
        class MyEncoder < ActiveEncode::Base
        end
      end
    end

    after :all do
      EncoderModule.send(:remove_const, :MyEncoder)
      Object.send(:remove_const, :EncoderModule)
      Object.send(:remove_const, :WorkflowEncoder)
    end

    it "should default to ActiveEncode::Base" do
      expect(subject.encoder_class).to eq(ActiveEncode::Base)
    end

    it "should infer the class from a workflow name" do
      subject.workflow_name = 'workflow_encoder'
      expect(subject.encoder_class).to eq(WorkflowEncoder)
    end

    it "should fall back to ActiveEncode::Base when a workflow class can't be resolved" do
      subject.workflow_name = 'nonexistent_workflow_encoder'
      expect(subject.encoder_class).to eq(ActiveEncode::Base)
    end

    it "should resolve an explicitly named encoder class" do
      subject.encoder_classname = 'EncoderModule::MyEncoder'
      expect(subject.encoder_class).to eq(EncoderModule::MyEncoder)
    end

    it "should fall back to ActiveEncode::Base when an encoder class can't be resolved" do
      subject.encoder_classname = 'EncoderModule::NonexistentEncoder'
      expect(subject.encoder_class).to eq(ActiveEncode::Base)
    end

    it "should correctly set the encoder classname from the encoder" do
      subject.encoder_class = EncoderModule::MyEncoder
      expect(subject.encoder_classname).to eq('EncoderModule::MyEncoder')
    end

    it "should reject an invalid encoder class" do
      expect { subject.encoder_class = Object }.to raise_error(ArgumentError)
    end
  end

  describe "#embed_title" do
    context "with structure" do
      subject { FactoryGirl.create( :master_file, :with_structure, { media_object: FactoryGirl.create( :media_object, { title: "test" })})}

      it "should favor the structure item label" do
        expect( subject.embed_title ).to eq( "test - CD 1" )
      end
    end

    context "without structure" do
      subject { FactoryGirl.create( :master_file, { media_object: FactoryGirl.create( :media_object, { title: "test" })})}

      it "should have an appropriate title for the embed code with a label" do
        subject.title = "test"
        expect( subject.embed_title ).to eq( "test - test" )
      end

      it "should have an appropriate title for the embed code with no label" do
        expect( subject.embed_title ).to eq( "test - video.mp4" )
      end

      it "should have an appropriate title for the embed code with no label or file_location" do
        subject.file_location = nil
        expect( subject.embed_title ).to eq( "test" )
      end
    end
  end

  describe "#update_ingest_batch" do
    let(:media_object) {FactoryGirl.create(:media_object)}
    let!(:ingest_batch) {IngestBatch.create(media_object_ids: [media_object.id], email: Faker::Internet.email)}
    let(:master_file) {FactoryGirl.create( :master_file , {media_object: media_object, status_code: 'COMPLETED'} )}
    it 'should send email when ingest batch is finished processing' do
      master_file.send(:update_ingest_batch)
      expect(ingest_batch.reload.email_sent?).to be true
    end
  end

  describe '#update_progress_on_success!' do
    subject(:master_file) { FactoryGirl.create(:master_file) }
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
    subject(:master_file) { FactoryGirl.create(:master_file, :with_structure) }
    it 'should return correct list of labels' do
      expect(master_file.structural_metadata_labels.first).to eq 'CD 1'
    end
  end

  describe 'rdf formatted information' do
    subject(:video_master_file) { FactoryGirl.create(:master_file) }
    subject(:sound_master_file) { FactoryGirl.create(:master_file, file_format: 'Sound') }
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
        expect { URI.parse(sound_master_file.rdf_uri) }.not_to raise_error
      end
      it 'returns a uri for a video master file' do
        expect(video_master_file.rdf_uri.class).to eq(String)
        expect { URI.parse(video_master_file.rdf_uri) }.not_to raise_error
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
  end

  describe '#extract_frame' do
    subject(:video_master_file) { FactoryGirl.create(:master_file, :with_media_object, :with_derivative, display_aspect_ratio: '1') }
    before do
      allow(video_master_file).to receive(:find_frame_source).and_return({source: video_master_file.file_location, offset: 1, master: false})
    end
    it "raises an exception when ffmpeg doesn't extract anything" do
      expect {video_master_file.send(:extract_frame, {size: '160x120', offset: 1})}.to raise_error(RuntimeError)
    end
  end

  describe 'poster' do
    let(:master_file) { FactoryGirl.create(:master_file) }
    it 'sets original_name to default value' do
      expect(master_file.poster.original_name).to eq 'poster.jpg'
    end
  end

  describe 'thumbnail' do
    let(:master_file) { FactoryGirl.create(:master_file) }
    it 'sets original_name to default value' do
      expect(master_file.thumbnail.original_name).to eq 'thumbnail.jpg'
    end
  end

  describe 'structuralMetadata' do
    let(:master_file) { FactoryGirl.create(:master_file) }
    it 'sets original_name to default value' do
      expect(master_file.structuralMetadata.original_name).to eq 'structuralMetadata.xml'
    end
  end

  describe 'update_parent!' do
    it 'does not error if the master file has no parent' do
      expect { MasterFile.new.send(:update_parent!) }.not_to raise_error
    end
  end

  describe 'stop_processing!' do
    before do
      allow(ActiveEncode::Base).to receive(:find).and_return(nil)
    end
    it 'does not error if the master file has no encode' do
      expect { MasterFile.new(workflow_id: '1', status_code: 'RUNNING').send(:stop_processing!) }.not_to raise_error
    end
  end
end
