# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

describe MasterFile do

  describe "validations" do
    subject {MasterFile.new}
    it {should validate_presence_of(:workflow_name)}
    it {should validate_inclusion_of(:workflow_name).in_array(MasterFile::WORKFLOWS)}
    xit {should validate_presence_of(:file_format)}
    xit {should validate_exclusion_of(:file_format).in_array(['Unknown']).with_message("The file was not recognized as audio or video.")}
  end

  describe "locations" do
    subject { 
      mf = MasterFile.new 
      mf.file_location = '/foo/bar/baz/quux.mp4'
      mf.save
      mf
    }

    it "should know where its (local) masterfile is" do
      expect(subject.file_location).to eq '/foo/bar/baz/quux.mp4'
      expect(subject.absolute_location).to eq 'file:///foo/bar/baz/quux.mp4'
    end

    it "should know where its (Samba remote) masterfile is" do
      Avalon::FileResolver.any_instance.stub(:mounts) { 
        ["//user@some.server.at.an.example.edu/stuff on /foo/bar (smbfs, nodev, nosuid, mounted by user)"]
      }
      expect(subject.absolute_location).to eq 'smb://some.server.at.an.example.edu/stuff/baz/quux.mp4'
    end

    it "should know where its (CIFS remote) masterfile is" do
      Avalon::FileResolver.any_instance.stub(:mounts) { 
        ["//user@some.server.at.an.example.edu/stuff on /foo/bar (cifs, nodev, nosuid, mounted by user)"]
      }
      expect(subject.absolute_location).to eq 'cifs://some.server.at.an.example.edu/stuff/baz/quux.mp4'
    end

    it "should know where its (NFS remote) masterfile is" do
      Avalon::FileResolver.any_instance.stub(:mounts) { 
        ["some.server.at.an.example.edu:/stuff on /foo/bar (nfs, nodev, nosuid, mounted by user)"]
      }
      expect(subject.absolute_location).to eq 'nfs://some.server.at.an.example.edu/stuff/baz/quux.mp4'
    end

    it "should follow the file to a new location" do
      subject.file_location = "/tmp/baz/quux.mp4"
      expect(subject.absolute_location).to eq 'file:///tmp/baz/quux.mp4'
    end

    it "should accept configurable overrides" do
      Avalon::FileResolver.any_instance.stub(:overrides) {
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

  describe "masterfiles=" do
    let(:derivative) {Derivative.create}
    let(:master_file) {FactoryGirl.create(:master_file)}
    it "should set hasDerivation relationships on self" do
      master_file.relationships(:is_derivation_of).size.should == 0

      master_file.derivatives += [derivative]

      derivative.relationships(:is_derivation_of).size.should == 1
      derivative.relationships(:is_derivation_of).first.should == master_file.internal_uri
    end
  end

  describe '#finished_processing?' do
    describe 'classifying statuses' do
      let(:master_file){ MasterFile.new }
      it 'returns true for stopped' do
        master_file.status_code = 'CANCELLED'
        master_file.finished_processing?.should be true
      end
      it 'returns true for succeeded' do
        master_file.status_code = 'COMPLETED'
        master_file.finished_processing?.should be true
      end
      it 'returns true for failed' do
        master_file.status_code = 'FAILED'
        master_file.finished_processing?.should be true
      end
    end
  end

  describe '#process' do
    let!(:master_file) { FactoryGirl.create(:master_file) }
    let(:encode_job) { ActiveEncodeJob::Create.new(master_file.pid, ActiveEncode::Base.new(nil)) }
    before do
      allow(ActiveEncodeJob::Create).to receive(:new).and_return(encode_job)
      allow(encode_job).to receive(:perform)
      Delayed::Worker.delay_jobs = false
    end
    after do
      Delayed::Worker.delay_jobs = true
    end
    it 'starts an ActiveEncode workflow' do
      master_file.process
      expect(encode_job).to have_received(:perform)
    end
    describe 'already processing' do
      before do
        master_file.status_code = 'RUNNING'
      end
      it 'should not start an ActiveEncode workflow' do
        expect{master_file.process}.to raise_error(RuntimeError)
        expect(encode_job).not_to have_received(:perform)
      end
    end
    describe 'failure' do
      before do
        allow(encode_job.encode).to receive(:create!).and_raise(Exception)
        Delayed::Worker.delay_jobs = true
      end
      after do
        Delayed::Worker.delay_jobs = false
      end
      it 'should set the status to FAILED when ActiveEncode::Base#create fails' do
        master_file.process
        #Have to manually tell delayed_job to do the work because callback doesn't get fired with delay_jobs = false
        Delayed::Worker.new.work_off
        master_file.reload
        expect(master_file.status_code).to eq('FAILED')
      end
    end
  end

  describe "delete" do
    subject(:masterfile) { derivative.masterfile }
    let(:derivative) {FactoryGirl.create(:derivative)}
    it "should delete (VOV-1805)" do
      allow(derivative).to receive(:delete).and_return true
      allow(ActiveEncode::Base).to receive(:stop)
      expect { masterfile.delete }.to change { MasterFile.all.count }.by(-1)
    end

    it "should delete with a nil parent (VOV-1357)" do
      masterfile.mediaobject = nil
      masterfile.save
      expect { masterfile.delete }.to change { MasterFile.all.count }.by(-1)
    end
  end

  describe "image_offset" do
    subject(:master_file) {FactoryGirl.create(:master_file, duration: (rand(21600000)+60000).to_s )}

    describe "milliseconds" do
      it "should accept a value" do
        offset = master_file.duration.to_i / 2
        master_file.poster_offset = offset
        master_file.poster_offset.should == offset.to_s
        master_file.should be_valid
      end

      it "should complain if value < 0" do
        master_file.poster_offset = -1
        master_file.should_not be_valid
        master_file.errors[:poster_offset].first.should == "must be between 0 and #{master_file.duration}"
      end

      it "should complain if value > duration" do
        offset = master_file.duration.to_i + rand(32514) + 500
        master_file.poster_offset = offset
        master_file.should_not be_valid
        master_file.errors[:poster_offset].first.should == "must be between 0 and #{master_file.duration}"
      end
    end

    describe "hh:mm:ss.sss" do
      it "should accept a value" do
        offset = master_file.duration.to_i / 2
        master_file.poster_offset = offset.to_hms
        master_file.poster_offset.should == offset.to_s
        master_file.should be_valid
      end

      it "should complain if value > duration" do
        offset = master_file.duration.to_i + rand(32514) + 500
        master_file.poster_offset = offset.to_hms
        master_file.should_not be_valid
        master_file.errors[:poster_offset].first.should == "must be between 0 and #{master_file.duration}"
      end
    end

    describe "update images" do
      it "should update on save" do
        MasterFile.should_receive(:extract_still).with(master_file.pid,{type:'both',offset:'12345'})
        master_file.poster_offset = 12345
        master_file.save
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
          master_file.workflow_name.should == 'avalon'
        end 
        it "should use the skipped transcoding workflow for video" do
          master_file.file_format = 'Moving image'
          master_file.set_workflow('skip_transcoding')
          master_file.workflow_name.should == 'avalon-skip-transcoding'
        end
      end

      describe "audio" do
        it "should not use the skipped transcoding workflow" do
          master_file.file_format = 'Sound'
          master_file.set_workflow
          master_file.workflow_name.should == 'fullaudio'
        end 
        it "should use the skipped transcoding workflow for video" do
          master_file.file_format = 'Sound'
          master_file.set_workflow('skip_transcoding')
          master_file.workflow_name.should == 'avalon-skip-transcoding-audio'
        end
      end
    end
    describe "video" do
      it "should use the avalon workflow" do
        master_file.file_format = 'Moving image'
        master_file.set_workflow
        master_file.workflow_name.should == 'avalon'
      end 
    end
    describe "audio" do
      it "should use the fullaudio workflow" do
        master_file.file_format = 'Sound'
        master_file.set_workflow
        master_file.workflow_name.should == 'fullaudio'
      end
    end
    describe "unknown format" do
      it "should set workflow_name to nil" do
        master_file.file_format = 'Unknown'
        master_file.set_workflow
        master_file.workflow_name.should == nil
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
          masterfile = FactoryGirl.create(:master_file)
          masterfile.setContent(derivative_hash)
          masterfile.file_location.should == filename_high
          masterfile.file_size.should == "199160"
        end
      end
      describe "quality-high does not exist" do
        it "should set the correct file location and size" do
          masterfile = FactoryGirl.create(:master_file)
          masterfile.setContent(derivative_hash.except("quality-high"))
          masterfile.file_location.should == filename_medium
          masterfile.file_size.should == "199160"
        end
      end

    end

    describe "single uploaded file" do
      describe "uploaded file" do
        let(:fixture)    { File.expand_path('../../fixtures/videoshort.mp4',__FILE__) }
        let(:original)   { File.basename(fixture) }
        let(:tempdir)    { File.realpath('/tmp') }
        let(:tempfile)   { File.join(tempdir, 'RackMultipart20130816-2519-y2wzc7') }
        let(:media_path) { File.expand_path("../../masterfiles-#{SecureRandom.uuid}",__FILE__)}
        let(:upload)     { ActionDispatch::Http::UploadedFile.new :tempfile => File.open(tempfile), :filename => original, :type => 'video/mp4' }
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
          subject.file_location.should == File.join(tempdir,original)
        end
        
        it "should copy an uploaded file to the media path" do
          Avalon::Configuration['matterhorn']['media_path'] = media_path
          subject.file_location.should == File.join(media_path,original)
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
    subject { FactoryGirl.create( :master_file, { mediaobject: FactoryGirl.create( :media_object, { title: "test" })})}

    it "should have an appropriate title for the embed code with no label" do
      expect( subject.embed_title ).to eq( "test - video.mp4" )
    end

    it "should have an appropriate title for the embed code with a label" do
      subject.label = "test"

      expect( subject.embed_title ).to eq( "test - test" )
    end
  end

  describe "#update_ingest_batch" do
    let(:media_object) {FactoryGirl.create(:media_object)}
    let!(:ingest_batch) {IngestBatch.create(media_object_ids: [media_object.id], email: Faker::Internet.email)}
    let(:master_file) {FactoryGirl.create( :master_file , {mediaobject: media_object, status_code: 'COMPLETED'} )}
    it 'should send email when ingest batch is finished processing' do
      master_file.send(:update_ingest_batch)
      expect(ingest_batch.reload.email_sent?).to be true
    end
  end
end
