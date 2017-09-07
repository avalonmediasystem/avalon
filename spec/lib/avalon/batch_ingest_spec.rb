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
require 'avalon/dropbox'
require 'avalon/batch/ingest'
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
    Avalon::RoleControls.add_user_role('frances.dickens@reichel.com','manager')
    Avalon::RoleControls.add_user_role('jay@krajcik.org','manager')
  end

  after :each do
    Avalon::Configuration['dropbox']['path'] = @saved_dropbox_path
    Dir['spec/fixtures/**/*.xlsx.process*','spec/fixtures/**/*.xlsx.error'].each { |file| File.delete(file) }
    Avalon::RoleControls.remove_user_role('frances.dickens@reichel.com','manager')
    Avalon::RoleControls.remove_user_role('jay@krajcik.org','manager')

    # this is a test environment, we don't want to kick off
    # generation jobs if possible
    allow_any_instance_of(MasterFile).to receive(:save).and_return(true)
  end

  describe 'scanning and registering new packages' do
    let(:collection) { FactoryGirl.create(:collection, name: 'Ut minus ut accusantium odio autem odit.', managers: ['frances.dickens@reichel.com']) }
    let(:batch_ingest) { Avalon::Batch::Ingest.new(collection) }

    before :each do
      @dropbox_dir = collection.dropbox.base_directory
      FileUtils.cp_r 'spec/fixtures/dropbox/example_batch_ingest', @dropbox_dir
      Avalon::Configuration['bib_retriever'] = { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db' }
      #stub_request(:get, sru_url).to_return(body: sru_response)
      @manifest_file = File.join(@dropbox_dir,'example_batch_ingest','batch_manifest.xlsx')
      @batch = Avalon::Batch::Package.new(@manifest_file, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [@batch]
    end

    after :each do
      if @dropbox_dir =~ %r{spec/fixtures/dropbox/Ut}
        FileUtils.rm_rf @dropbox_dir
      end
    end

    it 'registers a new package' do
      expect { batch_ingest.scan_for_packages }.to change { BatchRegistries.count }.by(1)
    end

    it 'does not persist anything to fedora' do
      expect(collection).to be_persisted
      expect { batch_ingest.scan_for_packages }.not_to change { ActiveFedora::Base.count }
    end
  end

  describe 'valid manifest' do
    let(:collection) { FactoryGirl.create(:collection, name: 'Ut minus ut accusantium odio autem odit.', managers: ['frances.dickens@reichel.com']) }
    let(:batch_ingest) { Avalon::Batch::Ingest.new(collection) }
    let(:bib_id) { '7763100' }
    let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=#{bib_id}" }
    let(:sru_response) { File.read(File.expand_path("../../../fixtures/#{bib_id}.xml",__FILE__)) }

    before :each do
      @dropbox_dir = collection.dropbox.base_directory
      FileUtils.cp_r 'spec/fixtures/dropbox/example_batch_ingest', @dropbox_dir
      Avalon::Configuration['bib_retriever'] = { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db' }
      stub_request(:get, sru_url).to_return(body: sru_response)
      manifest_file = File.join(@dropbox_dir,'example_batch_ingest','batch_manifest.xlsx')
      batch = Avalon::Batch::Package.new(manifest_file, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
    end

    after :each do
      if @dropbox_dir =~ %r{spec/fixtures/dropbox/Ut}
        FileUtils.rm_rf @dropbox_dir
      end
    end

    xit 'should send unlock the batch when it finished loading entries' do
      mailer = double('mailer').as_null_object
      expect(IngestBatchMailer).to receive(:batch_ingest_validation_success).with(duck_type(:each)).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      batch_ingest.ingest
    end

    it 'should skip the corrupt manifest' do
      manifest_file = File.join(@dropbox_dir,'example_batch_ingest','bad_manifest.xlsx')
      batch = Avalon::Batch::Package.new(manifest_file, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      expect { batch_ingest.scan_for_packages }.not_to raise_error
      expect { batch_ingest.scan_for_packages }.not_to change{IngestBatch.count}
      error_file = File.join(@dropbox_dir,'example_batch_ingest','bad_manifest.xlsx.error')
      expect(File.exists?(error_file)).to be true
      expect(File.read(error_file)).to match(/^Invalid manifest/)
    end

    it 'should ingest batch with spaces in name' do
      space_batch_path = File.join('spec/fixtures/dropbox/example batch ingest', 'batch manifest with spaces.xlsx')
      space_batch = Avalon::Batch::Package.new(space_batch_path, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [space_batch]
      expect{batch_ingest.scan_for_packages}.to change{BatchRegistries.count}.by(1)
    end

    it 'should ingest batch with skip-transcoding derivatives' do
      derivatives_batch_path = File.join('spec/fixtures/dropbox/pretranscoded_batch_ingest', 'batch_manifest_derivatives.xlsx')
      derivatives_batch = Avalon::Batch::Package.new(derivatives_batch_path, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [derivatives_batch]
      expect{batch_ingest.scan_for_packages}.to change{BatchRegistries.count}.by(1)
    end

    it 'creates an ingest batch object' do
      expect{batch_ingest.scan_for_packages}.to change{BatchRegistries.count}.by(1)
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
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return []
      #expect(IngestBatchMailer).to receive(:batch_ingest_validation_error).with(anything(), include("Expected error message"))
      expect{batch_ingest.ingest}.to_not change{IngestBatch.count}
    end

    it 'should result in an error if a file is not found' do
      batch = Avalon::Batch::Package.new( 'spec/fixtures/dropbox/example_batch_ingest/wrong_filename_manifest.xlsx', collection )
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      expect(IngestBatchMailer).to receive(:batch_ingest_validation_error).with(duck_type(:each),duck_type(:each)).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect{batch_ingest.ingest}.to_not change{IngestBatch.count}
      expect(batch.errors[3].messages).to have_key(:content)
      expect(batch.errors[3].messages[:content]).to eq(["File not found: spec/fixtures/dropbox/example_batch_ingest/assets/sheephead_mountain_wrong.mov"])
    end

    it 'does not create an ingest batch object when there are no files' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/no_files.xlsx', collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      expect{batch_ingest.ingest}.to_not change{IngestBatch.count}
    end

    it 'should fail if the manifest specified a non-manager user' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/non_manager_manifest.xlsx', collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      expect(IngestBatchMailer).to receive(:batch_ingest_validation_error).with(anything(), include("User jay@krajcik.org does not have permission to add items to collection: Ut minus ut accusantium odio autem odit..")).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect{batch_ingest.ingest}.to_not change{IngestBatch.count}
    end

    it 'should fail if a bad offset is specified' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/bad_offset_manifest.xlsx', collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      expect(IngestBatchMailer).to receive(:batch_ingest_validation_error).with(duck_type(:each),duck_type(:each)).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect{batch_ingest.ingest}.to_not change{IngestBatch.count}
      expect(batch.errors[4].messages).to have_key(:offset)
      expect(batch.errors[4].messages[:offset]).to eq(['Invalid offset: 5:000'])
    end

    it 'should fail if missing required field' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/missing_required_field.xlsx', collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      expect(IngestBatchMailer).to receive(:batch_ingest_validation_error).with(duck_type(:each),duck_type(:each)).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect{batch_ingest.ingest}.to_not change{IngestBatch.count}
      expect(batch.errors[4].messages).to have_key(:title)
      expect(batch.errors[4].messages[:title]).to eq(['field is required.'])
    end

    it 'should fail if field is not in accepted metadata field list' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/badColumnName_nonRequired.xlsx', collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      expect(IngestBatchMailer).to receive(:batch_ingest_validation_error).with(duck_type(:each),duck_type(:each)).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect{batch_ingest.ingest}.to_not change{IngestBatch.count}
      expect(batch.errors[4].messages).to have_key(:contributator)
      expect(batch.errors[4].messages[:contributator]).to eq(["unknown attribute 'contributator' for MediaObject."])
    end

    it 'should fail if an unknown error occurs' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/badColumnName_nonRequired.xlsx', collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      mailer = double('mailer').as_null_object
      expect(IngestBatchMailer).to receive(:batch_ingest_validation_error).with(batch ,['RuntimeError: Foo']).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect(batch_ingest).to receive(:ingest_package) { raise "Foo" }
      expect { batch_ingest.ingest }.to_not raise_error
    end
  end

  it "should be able to default to public access" do
    skip "[VOV-1348] Wait until implemented"
  end

  it "should be able to default to specific groups" do
    skip "[VOV-1348] Wait until implemented"
  end
end
