# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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
  subject { FactoryGirl.build(:batch_entries) }

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
        be = BatchEntries.new(payload: payload.to_json)
        be.save
        be.reload
        expect(be.error).to be_falsey
      end

      it 'does not record an error when bibliographic_id is present' do
        payload = { fields: { bibliographic_id: 'foo' } }
        be = BatchEntries.new(payload: payload.to_json)
        be.save
        be.reload
        expect(be.error).to be_falsey
      end
    end
    describe 'with insufficient metadata' do
      it 'records an error when no required fields are present' do
        payload = { fields: { author: 'foo' } }
        be = BatchEntries.new(payload: payload.to_json)
        be.save
        be.reload
        expect(be.error).to be_truthy
      end
      it 'records an error when only title is present' do
        payload = { fields: { title: 'foo' } }
        be = BatchEntries.new(payload: payload.to_json)
        be.save
        be.reload
        expect(be.error).to be_truthy
      end
      it 'records an error when only date issued is present' do
        payload = { fields: { date_issued: Time.now.utc } }
        be = BatchEntries.new(payload: payload.to_json)
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
end
