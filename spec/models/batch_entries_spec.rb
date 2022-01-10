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

describe BatchEntries do
  let(:batch_registry) { FactoryBot.build(:batch_registries) }
  subject { FactoryBot.build(:batch_entries, batch_registries: batch_registry) }

  describe '#save' do
    it 'persists' do
      subject.save
      subject.reload
      expect(subject.batch_registries).to be_present
      expect(subject.current_status).to be_present
      expect(subject.media_object_pid).to be_present
      expect(subject.position).to be_present
      expect(subject.payload).to be_present
      expect(subject.complete).not_to be_nil
      expect(subject.error).not_to be_nil
    end
  end

  describe 'validating payload' do
    describe 'with sufficient metadata' do
      it 'does not record an error when title and date_issued are present' do
        payload = { fields: { title: 'foo', date_issued: Time.now.utc } }
        be = BatchEntries.new(payload: payload.to_json, batch_registries: batch_registry)
        be.save
        be.reload
        expect(be.error).to be_falsey
      end

      it 'does not record an error when bibliographic_id is present' do
        payload = { fields: { bibliographic_id: 'foo' } }
        be = BatchEntries.new(payload: payload.to_json, batch_registries: batch_registry)
        be.save
        be.reload
        expect(be.error).to be_falsey
      end
    end
    describe 'with insufficient metadata' do
      it 'records an error when no required fields are present' do
        payload = { fields: { author: 'foo' } }
        be = BatchEntries.new(payload: payload.to_json, batch_registries: batch_registry)
        be.save
        be.reload
        expect(be.error).to be_truthy
      end
      it 'records an error when only title is present' do
        payload = { fields: { title: 'foo' } }
        be = BatchEntries.new(payload: payload.to_json, batch_registries: batch_registry)
        be.save
        be.reload
        expect(be.error).to be_truthy
      end
      it 'records an error when only date issued is present' do
        payload = { fields: { date_issued: Time.now.utc } }
        be = BatchEntries.new(payload: payload.to_json, batch_registries: batch_registry)
        be.save
        be.reload
        expect(be.error).to be_truthy
      end
    end
  end

  describe '#queue' do
    it 'queues the ingest job' do
      subject.save
      expect(IngestBatchEntryJob).to receive(:perform_later).once.with(subject)
      subject.queue
      subject.reload
      expect(subject.current_status).to eq 'Queued'
    end
  end

  describe 'encoding tracking' do
    it 'records an encoding error if the media_object_pid is blank' do
      batch_entry = FactoryBot.build(:batch_entries, media_object_pid: nil)

      expect(batch_entry.encoding_finished?).to be_truthy
      expect(batch_entry.encoding_success?).to be_falsey
      expect(batch_entry.encoding_error?).to be_truthy
    end

    it 'records an encoding error if the MediaObject is not in Fedora' do
      batch_entry = FactoryBot.build(:batch_entries, media_object_pid: 'nope')

      expect(batch_entry.encoding_finished?).to be_truthy
      expect(batch_entry.encoding_success?).to be_falsey
      expect(batch_entry.encoding_error?).to be_truthy
    end

    it 'records an encoding error if the MediaObject does not have enough MasterFiles' do
      media_object = FactoryBot.create(:media_object)
      batch_entry = FactoryBot.build(:batch_entries, media_object_pid: media_object.id)

      expect(media_object.master_files.to_a.count).to eq(0)
      expect(JSON.parse(batch_entry.payload)['files'].count).to eq(1)

      expect(batch_entry.encoding_finished?).to be_truthy
      expect(batch_entry.encoding_success?).to be_falsey
      expect(batch_entry.encoding_error?).to be_truthy
    end

    it 'records an encoding success if the MediaObject has MasterFiles that are complete' do
      master_file = FactoryBot.create(:master_file, :with_media_object, :completed_processing)
      media_object = master_file.media_object
      batch_entry = FactoryBot.build(:batch_entries, media_object_pid: media_object.id)

      expect(media_object.master_files.to_a.count).to eq(1)
      expect(JSON.parse(batch_entry.payload)['files'].count).to eq(1)

      expect(batch_entry.encoding_finished?).to be_truthy
      expect(batch_entry.encoding_success?).to be_truthy
      expect(batch_entry.encoding_error?).to be_falsey
    end

    it 'records an encoding error if the MediaObject has MasterFiles that have errored' do
      master_file = FactoryBot.create(:master_file, :with_media_object, :failed_processing)
      media_object = master_file.media_object
      batch_entry = FactoryBot.build(:batch_entries, media_object_pid: media_object.id)

      expect(media_object.master_files.to_a.count).to eq(1)
      expect(JSON.parse(batch_entry.payload)['files'].count).to eq(1)

      expect(batch_entry.encoding_finished?).to be_truthy
      expect(batch_entry.encoding_success?).to be_falsey
      expect(batch_entry.encoding_error?).to be_truthy
    end

    it 'records an encoding error if the MediaObject has MasterFiles that are cancelled' do
      master_file = FactoryBot.create(:master_file, :with_media_object, :cancelled_processing)
      media_object = master_file.media_object
      batch_entry = FactoryBot.build(:batch_entries, media_object_pid: media_object.id)

      expect(media_object.master_files.to_a.count).to eq(1)
      expect(JSON.parse(batch_entry.payload)['files'].count).to eq(1)

      expect(batch_entry.encoding_finished?).to be_truthy
      expect(batch_entry.encoding_success?).to be_falsey
      expect(batch_entry.encoding_error?).to be_truthy
    end

    it 'records neither error nor success nor finished if MediaObject has MasterFiles that are not errored or successful' do
      master_file = FactoryBot.create(:master_file, :with_media_object)
      media_object = master_file.media_object
      batch_entry = FactoryBot.build(:batch_entries, media_object_pid: media_object.id)

      expect(media_object.master_files.to_a.count).to eq(1)
      expect(JSON.parse(batch_entry.payload)['files'].count).to eq(1)

      expect(batch_entry.encoding_finished?).to be_falsey
      expect(batch_entry.encoding_success?).to be_falsey
      expect(batch_entry.encoding_error?).to be_falsey
    end

    it 'records neither error nor success nor finished if MediaObject has any MasterFiles that are not errored or successful' do
      master_file1 = FactoryBot.create(:master_file, :with_media_object, :completed_processing)
      media_object = master_file1.media_object
      master_file2 = FactoryBot.create(:master_file, :failed_processing, media_object: media_object)
      master_file3 = FactoryBot.create(:master_file, media_object: media_object)

      batch_entry = FactoryBot.build(:batch_entries, media_object_pid: media_object.id)
      files = double()
      allow(batch_entry).to receive(:files).and_return(files)
      allow(files).to receive(:count).and_return(3)

      expect(batch_entry.encoding_finished?).to be_falsey
      expect(batch_entry.encoding_success?).to be_falsey
      expect(batch_entry.encoding_error?).to be_falsey
    end
  end
end
