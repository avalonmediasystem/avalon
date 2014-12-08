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
require 'avalon/dropbox'
require 'avalon/batch_ingest'
require 'fileutils'

describe Avalon::Batch::Ingest do
  before :each do
    @saved_dropbox_path = Avalon::Configuration.lookup('dropbox.path')
    Avalon::Configuration['dropbox']['path'] = 'spec/fixtures/dropbox'
    Avalon::Configuration['email']['notification'] = 'frances.dickens@reichel.com'
    # Dirty hack is to remove the .processed files both before and after the
    # test. Need to look closer into the ideal timing for where this should take
    # place
    # this file is created to signify that the file has been processed
    # we need to remove it so can re-run the tests
    Dir['spec/fixtures/**/*.xlsx.process*','spec/fixtures/**/*.xlsx.error'].each { |file| File.delete(file) }

    User.create(:username => 'frances.dickens@reichel.com', :email => 'frances.dickens@reichel.com')
    User.create(:username => 'jay@krajcik.org', :email => 'jay@krajcik.org')
    RoleControls.add_user_role('frances.dickens@reichel.com','manager')
    RoleControls.add_user_role('jay@krajcik.org','manager')
  end

  after :each do
    Avalon::Configuration['dropbox']['path'] = @saved_dropbox_path
    Dir['spec/fixtures/**/*.xlsx.process*','spec/fixtures/**/*.xlsx.error'].each { |file| File.delete(file) }
    RoleControls.remove_user_role('frances.dickens@reichel.com','manager')
    RoleControls.remove_user_role('jay@krajcik.org','manager')
    
    # this is a test environment, we don't want to kick off
    # generation jobs if possible
    MasterFile.any_instance.stub(:save).and_return(true)
  end

  describe 'valid manifest' do
    let(:collection) { FactoryGirl.create(:collection, name: 'Ut minus ut accusantium odio autem odit.', managers: ['frances.dickens@reichel.com']) }
    let(:batch_ingest) { Avalon::Batch::Ingest.new(collection) }

    before :each do
      @dropbox_dir = collection.dropbox.base_directory
      FileUtils.cp_r 'spec/fixtures/dropbox/example_batch_ingest', @dropbox_dir
    end

    after :each do
      if @dropbox_dir =~ %r{spec/fixtures/dropbox/Ut} 
        FileUtils.rm_rf @dropbox_dir
      end
    end

    it 'should send email when batch finishes processing' do
      mailer = double('mailer').as_null_object
      IngestBatchMailer.should_receive(:batch_ingest_validation_success).with(duck_type(:each)).and_return(mailer)
      mailer.should_receive(:deliver)
      batch_ingest.ingest
    end
    
    it 'should skip the corrupt manifest' do
      lambda { batch_ingest.ingest }.should_not raise_error
      error_file = File.join(@dropbox_dir,'example_batch_ingest','bad_manifest.xlsx.error')
      File.exists?(error_file).should be true
      File.read(error_file).should =~ /^Invalid manifest/
    end
    
    it 'should ingest batch with spaces in name' do
      space_batch_path = File.join('spec/fixtures/dropbox/example batch ingest', 'batch manifest with spaces.xlsx')
      space_batch = Avalon::Batch::Package.new(space_batch_path, collection)
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return [space_batch]
      batch_ingest.ingest
      IngestBatch.count.should == 1
    end

    it 'creates an ingest batch object' do
      batch_ingest.ingest
      IngestBatch.count.should == 1
    end

    it 'should set MasterFile details' do
      batch_ingest.ingest
      ingest_batch = IngestBatch.first
      media_object = MediaObject.find(ingest_batch.media_object_ids.first) 
      master_file = media_object.parts.first
      master_file.label.should == 'Quis quo'
      master_file.poster_offset.to_i.should == 500
      master_file.workflow_name.should == 'avalon'
      master_file.absolute_location.should == Avalon::FileResolver.new.path_to(master_file.file_location) 

      # if a master file is saved on a media object 
      # it should have workflow name set
      # master_file.workflow_name.should be_nil

      master_file = media_object.parts[1]
      master_file.label.should == 'Unde aliquid'
      master_file.poster_offset.to_i.should == 500
      master_file.workflow_name.should == 'avalon-skip-transcoding'
      master_file.absolute_location.should == 'file:///tmp/sheephead_mountain_master.mov'

      master_file = media_object.parts[2]
      master_file.label.should == 'Audio'
      master_file.workflow_name.should == 'fullaudio'
      master_file.absolute_location.should == Avalon::FileResolver.new.path_to(master_file.file_location)
    end

    it 'should set avalon_uploader' do
      batch_ingest.ingest
      ingest_batch = IngestBatch.first
      media_object = MediaObject.find(ingest_batch.media_object_ids.first)
      media_object.avalon_uploader.should == 'frances.dickens@reichel.com'
    end

    it 'should set hidden' do
      batch_ingest.ingest
      ingest_batch = IngestBatch.first
      media_object = MediaObject.find(ingest_batch.media_object_ids.first)
      media_object.should_not be_hidden

      media_object = MediaObject.find(ingest_batch.media_object_ids[1])
      media_object.should be_hidden
    end

    it 'should correctly set identifiers' do
      batch_ingest.ingest
      ingest_batch = IngestBatch.first
      media_object = MediaObject.find(ingest_batch.media_object_ids.first)
      media_object.bibliographic_id.should eq(["local","123"])
    end

  end

  describe 'invalid manifest' do
    let(:collection) { FactoryGirl.create(:collection, name: 'Ut minus ut accusantium odio autem odit.', managers: ['frances.dickens@reichel.com']) }
    let(:batch_ingest) { Avalon::Batch::Ingest.new(collection) }
    let(:dropbox) { collection.dropbox }

    before :each do
      @dropbox_dir = collection.dropbox.base_directory
    end

    after :each do
      if @dropbox_dir =~ %r{spec/fixtures/dropbox/Ut} 
        FileUtils.rm_rf @dropbox_dir
      end
    end

    it 'does not create an ingest batch object when there are zero packages' do
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return []
      #expect(IngestBatchMailer).to receive(:batch_ingest_validation_error).with(anything(), include("Expected error message"))
      batch_ingest.ingest
      IngestBatch.count.should == 0
    end

    it 'should result in an error if a file is not found' do
      batch = Avalon::Batch::Package.new( 'spec/fixtures/dropbox/example_batch_ingest/wrong_filename_manifest.xlsx', collection )
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      IngestBatchMailer.should_receive(:batch_ingest_validation_error).with(duck_type(:each),duck_type(:each)).and_return(mailer)
      mailer.should_receive(:deliver)
      batch_ingest.ingest
      IngestBatch.count.should == 0
      batch.errors[3].messages.should have_key(:content)
      batch.errors[3].messages[:content].should eq(["File not found: spec/fixtures/dropbox/example_batch_ingest/assets/sheephead_mountain_wrong.mov"])
    end

    it 'does not create an ingest batch object when there are no files' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/no_files.xlsx', collection)
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return [batch]
      batch_ingest.ingest
      IngestBatch.count.should == 0
    end

    it 'should fail if the manifest specified a non-manager user' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/non_manager_manifest.xlsx', collection)
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      IngestBatchMailer.should_receive(:batch_ingest_validation_error).with(anything(), include("User jay@krajcik.org does not have permission to add items to collection: Ut minus ut accusantium odio autem odit..")).and_return(mailer)
      mailer.should_receive(:deliver)
      batch_ingest.ingest
      IngestBatch.count.should == 0
    end

    it 'should fail if a bad offset is specified' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/bad_offset_manifest.xlsx', collection)
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      IngestBatchMailer.should_receive(:batch_ingest_validation_error).with(duck_type(:each),duck_type(:each)).and_return(mailer)
      mailer.should_receive(:deliver)
      batch_ingest.ingest
      IngestBatch.count.should == 0
      batch.errors[4].messages.should have_key(:offset)
      batch.errors[4].messages[:offset].should eq(['Invalid offset: 5:000'])
    end

    it 'should fail if missing required field' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/missing_required_field.xlsx', collection)
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      IngestBatchMailer.should_receive(:batch_ingest_validation_error).with(duck_type(:each),duck_type(:each)).and_return(mailer)
      mailer.should_receive(:deliver)
      batch_ingest.ingest
      IngestBatch.count.should == 0
      batch.errors[4].messages.should have_key(:creator)
      batch.errors[4].messages[:creator].should eq(['field is required.'])
    end

    it 'should fail if field is not in accepted metadata field list' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/badColumnName_nonRequired.xlsx', collection)
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      IngestBatchMailer.should_receive(:batch_ingest_validation_error).with(duck_type(:each),duck_type(:each)).and_return(mailer)
      mailer.should_receive(:deliver)
      batch_ingest.ingest
      IngestBatch.count.should == 0
      batch.errors[4].messages.should have_key(:contributator)
      batch.errors[4].messages[:contributator].should eq(["Metadata attribute 'contributator' not found"])
    end
    
    it 'should fail if an unknown error occurs' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/badColumnName_nonRequired.xlsx', collection)
      Avalon::Dropbox.any_instance.stub(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      IngestBatchMailer.should_receive(:batch_ingest_validation_error).with(batch ,['RuntimeError: Foo']).and_return(mailer)
      mailer.should_receive(:deliver)
      batch_ingest.should_receive(:ingest_package) { raise "Foo" }
      expect { batch_ingest.ingest }.to_not raise_error
    end
  end

  it "should be able to default to public access" do
    skip "[VOV-1348] Wait until implemented"
  end

  it "should be able to default to specific groups" do
    skip "[VOV-1348] Wait until implemented"
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
end
