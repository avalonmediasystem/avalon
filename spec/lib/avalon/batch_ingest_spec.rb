# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
    @saved_dropbox_path = Settings.dropbox.path
    Settings.dropbox.path = File.join(Rails.root, 'spec/fixtures/dropbox')
    Settings.email.notification = 'frances.dickens@reichel.com'
    # Dirty hack is to remove the .processed files both before and after the
    # test. Need to look closer into the ideal timing for where this should take
    # place
    # this file is created to signify that the file has been processed
    # we need to remove it so can re-run the tests
    Dir['spec/fixtures/**/*.xlsx.process*','spec/fixtures/**/*.xlsx.error'].each { |file| File.delete(file) }

    FactoryBot.create(:user, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com')
    FactoryBot.create(:user, username: 'jay@krajcik.org', email: 'jay@krajcik.org')
    Avalon::RoleControls.add_user_role('frances.dickens@reichel.com','manager')
    Avalon::RoleControls.add_user_role('jay@krajcik.org','manager')
    allow(IngestBatchEntryJob).to receive(:perform_later).and_return(nil)
  end

  after :each do
    Settings.dropbox.path = @saved_dropbox_path
    Dir['spec/fixtures/**/*.xlsx.process*','spec/fixtures/**/*.xlsx.error'].each { |file| File.delete(file) }
    Avalon::RoleControls.remove_user_role('frances.dickens@reichel.com','manager')
    Avalon::RoleControls.remove_user_role('jay@krajcik.org','manager')

    # this is a test environment, we don't want to kick off
    # generation jobs if possible
    allow_any_instance_of(MasterFile).to receive(:save).and_return(true)
  end

  describe 'scanning and registering new packages' do
    let(:collection) { FactoryBot.create(:collection, name: 'Ut minus ut accusantium odio autem odit.', managers: ['frances.dickens@reichel.com']) }
    let(:batch_ingest) { Avalon::Batch::Ingest.new(collection) }

    before :each do
      @dropbox_dir = collection.dropbox.base_directory
      FileUtils.cp_r 'spec/fixtures/dropbox/example_batch_ingest', @dropbox_dir
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

    it 'deletes the manifest after registering' do
       batch_ingest.scan_for_packages
       expect(FileLocator.new(@batch.manifest.file).exists?).to be_falsey
    end

    it 'does not persist anything to fedora' do
      expect(collection).to be_persisted
      expect { batch_ingest.scan_for_packages }.not_to change { ActiveFedora::Base.count }
    end
  end

  describe 'valid manifest' do
    let(:collection) { FactoryBot.create(:collection, name: 'Ut minus ut accusantium odio autem odit.', managers: ['frances.dickens@reichel.com']) }
    let(:batch_ingest) { Avalon::Batch::Ingest.new(collection) }
    let(:bib_id) { '7763100' }
    let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=#{bib_id}" }
    let(:sru_response) { File.read(File.expand_path("../../../fixtures/#{bib_id}.xml",__FILE__)) }

    before :each do
      @dropbox_dir = collection.dropbox.base_directory
      FileUtils.cp_r 'spec/fixtures/dropbox/example_batch_ingest', @dropbox_dir
      stub_request(:get, sru_url).to_return(body: sru_response)
      manifest_file = File.join(@dropbox_dir,'example_batch_ingest','batch_manifest.xlsx')
      batch = Avalon::Batch::Package.new(manifest_file, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
    end

    after :each do
      if @dropbox_dir =~ %r{spec/fixtures/dropbox/Ut}
        FileUtils.rm_rf @dropbox_dir
      end
      BatchEntries.delete_all
      BatchRegistries.delete_all
    end

    it 'should skip the corrupt manifest' do
      manifest_file = File.join(@dropbox_dir,'example_batch_ingest','bad_manifest.xlsx')
      batch = Avalon::Batch::Package.new(manifest_file, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      expect { batch_ingest.scan_for_packages }.not_to raise_error
      expect { batch_ingest.scan_for_packages }.not_to change{BatchRegistries.count}
      error_file = File.join(@dropbox_dir,'example_batch_ingest','bad_manifest.xlsx.error')
      expect(File.exists?(error_file)).to be true
      expect(File.read(error_file)).to match(/^Invalid manifest/)
    end

    it 'should ingest batch with spaces in name' do
      FileUtils.cp_r 'spec/fixtures/dropbox/example batch ingest', @dropbox_dir
      space_batch_path = File.join(@dropbox_dir + '/example batch ingest', 'batch manifest with spaces.xlsx')
      space_batch = Avalon::Batch::Package.new(space_batch_path, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [space_batch]
      expect{batch_ingest.scan_for_packages}.to change{BatchRegistries.count}.by(1)
    end

    it 'should ingest batch with skip-transcoding derivatives' do
      FileUtils.cp_r 'spec/fixtures/dropbox/pretranscoded_batch_ingest', @dropbox_dir
      derivatives_batch_path = File.join(@dropbox_dir + '/pretranscoded_batch_ingest', 'batch_manifest_derivatives.xlsx')
      derivatives_batch = Avalon::Batch::Package.new(derivatives_batch_path, collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [derivatives_batch]
      expect{batch_ingest.scan_for_packages}.to change{BatchRegistries.count}.by(1)
    end

    it 'creates an ingest batch object' do
      expect{batch_ingest.scan_for_packages}.to change{BatchRegistries.count}.by(1)
    end

    describe 'registering entries' do
      it 'registers entries' do
        expect { batch_ingest.scan_for_packages }.to change { BatchEntries.count }.by(3)
      end

      it 'gets previous entries when there is a replay' do
        batch_ingest.scan_for_packages
        # Fake the replay name for the test and rerun the same package
        br = BatchRegistries.first
        br.replay_name = br.file_name
        br.save
        expect(batch_ingest.fetch_previous_entries).not_to be_nil
      end

      it 'does not get previous when there is not a replay' do
        expect(batch_ingest).not_to receive(:fetch_previous_entries)
        batch_ingest.scan_for_packages
      end

      it 'queues ingest jobs for newly registered entries' do
        allow_any_instance_of(BatchEntries).to receive(:queue)
        batch_ingest.scan_for_packages
      end

      describe 'replays on entries' do
        before :each do
          # Set up a replay of the default batch
          batch_ingest.scan_for_packages
          br = BatchRegistries.first
          br.replay_name = br.file_name
          br.save
          # Get the old timestamps
          ts = []
          BatchEntries.all do |be|
            ts << be.updated_at
          end
        end

        it 'does not change the entries if there are no changes' do
          # Run the replay
          batch_ingest.scan_for_packages

          # Timestamps should not have changed
          pos = 0
          BatchEntries.all do |be|
            expect(be.updated_at).to eq(ts[pos])
            pos += 1
          end
        end

        it 'changes the entries when if there are changes' do
          BatchEntries.all do |be|
            be.payload = 'foo'
            be.save
          end

          # Timestamps should have changed and payload updated
          pos = 0
          BatchEntries.all do |be|
            expect(be.payload).not_to eq('foo')
            expect(be.updated_at).not_to eq(ts[pos])
            pos += 1
          end
        end

        it 'resets the entries when the entries are errored out' do
          BatchEntries.all do |be|
            be.error = true
            be.payload = 'foo'
            be.save
          end

          # Timestamps should have changed and errors cleared
          pos = 0
          BatchEntries.all do |be|
            expect(be.payload).not_to eq('foo')
            expect(be.error).to_be falsey
            expect(be.updated_at).not_to eq(ts[pos])
            pos += 1
          end
        end

        it 'requeues completed objects when the MediaObject has not been published' do
          allow(MediaObject).to receive(:exists?).with(anything).and_return(false)
          BatchEntries.all do |be|
            be.completed = true
            be.payload = 'foo'
            be.media_object_pid = 'foo'
            be.save
          end

          # Timestamps should have changed and completed status removed
          pos = 0
          BatchEntries.all do |be|
            expect(be.payload).not_to eq('foo')
            expect(be.completed).to_be falsey
            expect(be.updated_at).not_to eq(ts[pos])
            pos += 1
          end
        end

        it 'does not requeue jobs when the media objects are published' do
          allow(MediaObject).to receive(:exists?).with(anything).and_return(true)
          BatchEntries.all do |be|
            be.completed = true
            be.media_object_pid = 'foo'
            be.save
          end

          # Timestamps should have changed and completed status removed
          pos = 0
          BatchEntries.all do |be|
            expect(be.payload).not_to eq('foo')
            expect(be.completed).to_be falsey
            expect(be.error).to_be true
            expect(be.updated_at).not_to eq(ts[pos])
            pos += 1
          end
        end


      end
    end

    describe 'registering batches' do
      it 'registers a new package' do
        expect(BatchRegistries.first).to be_nil
        expect { batch_ingest.scan_for_packages }.to change { BatchRegistries.count }.by(1)
        expect(batch_ingest).not_to receive(:register_replay)
        expect(BatchRegistries.first.locked).to be_falsey
      end

      it 'sends a registration success email' do
        expect(BatchRegistriesMailer).to receive(:batch_ingest_validation_success).and_call_original
        batch_ingest.scan_for_packages
      end

      it 'registers a replay package' do
        expect(BatchRegistries.first).to be_nil
        # Set up the replay
        batch_ingest.scan_for_packages
        br = BatchRegistries.first
        br.replay_name = br.file_name
        br.save
        expect(BatchRegistries.all.size).to eq(1)

        # Run it with a replay, expect no size changes
        expect { batch_ingest.scan_for_packages }.to change { BatchRegistries.count }.by(0)
        expect { batch_ingest.scan_for_packages }.to change { BatchEntries.count }.by(0)
        expect(batch_ingest).not_to receive(:register_batch)
        expect(BatchRegistries.first.locked).to be_falsey
      end
    end
  end

  describe 'invalid manifest' do
    let(:collection) { FactoryBot.create(:collection, name: 'Ut minus ut accusantium odio autem odit.', managers: ['frances.dickens@reichel.com']) }
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
      expect { batch_ingest.scan_for_packages }.to_not change { BatchRegistries.count }
    end

    it 'should fail if the manifest specified a non-manager user' do
      batch = Avalon::Batch::Package.new('spec/fixtures/dropbox/example_batch_ingest/non_manager_manifest.xlsx', collection)
      allow_any_instance_of(Avalon::Dropbox).to receive(:find_new_packages).and_return [batch]
      expect(batch_ingest).to receive(:send_invalid_package_email).once
      expect { batch_ingest.scan_for_packages }.to_not change { BatchRegistries.count }
      # it should create an error file and not attempt to reregister the package until user action
      expect(batch.manifest.error?).to be true
    end
  end
end
