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

describe IngestBatch do
  it 'persists media object ids' do
    media_object_ids = ['first-item', 'second-item', 'third-item']
    ingest_batch = IngestBatch.create(media_object_ids: media_object_ids)
    ingest_batch.reload
    expect(ingest_batch.media_object_ids).to eq(media_object_ids)
  end
  describe '#finished?' do
    it 'returns true when all the master files are finished' do
      media_object = FactoryBot.create(:media_object, master_files: [FactoryBot.create(:master_file, :cancelled_processing), FactoryBot.create(:master_file, :completed_processing)])
      ingest_batch = IngestBatch.new(media_object_ids: [media_object.id], email: 'email@something.com')
      expect(ingest_batch.finished?).to be true
    end

    # fix: adding master_files to media object parts is broken
    it 'returns false when one or more master files are not finished' do
       skip "Fix problems with this test"

       media_object = MediaObject.new(id:'avalon:ingest-batch-test')
       media_object.add_relationship(:has_part, FactoryBot.build(:master_file, :completed_processing))
       media_object.parts << FactoryBot.build(:master_file)
       media_object.save
       ingest_batch = IngestBatch.new(media_object_ids: ['avalon:ingest-batch-test'], email: 'email@something.com')
       expect(ingest_batch.finished?).to be true
    end
  end

  describe '#media_objects' do
    it 'returns an empty array if media_object_ids is nil' do
      n = IngestBatch.new
      expect(n.media_objects).to eq([])
    end

    it 'returns an array of media objects based on ids passed in' do
      media_objects = Array.new(3) { FactoryBot.create(:media_object) }
      ingest_batch = IngestBatch.new(media_object_ids:media_objects.map(&:id))
      expect(ingest_batch.media_objects).to eq(media_objects)
    end
  end

  describe '#email_sent?' do
    let(:ingest_batch){ IngestBatch.new }
    it 'returns true if email_sent is true' do
      ingest_batch.email_sent = true
      expect(ingest_batch.email_sent?).to be true
    end
    it 'returns false if email_sent is false' do
      ingest_batch.email_sent = false
      expect(ingest_batch.email_sent?).to be false
    end
  end
end
