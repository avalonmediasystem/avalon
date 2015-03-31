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

describe IngestBatch do
  it 'persists media object ids' do
    media_object_ids = ['first-item', 'second-item', 'third-item']
    ingest_batch = IngestBatch.create(media_object_ids: media_object_ids)
    ingest_batch.reload
    ingest_batch.media_object_ids.should == media_object_ids
  end
  describe '#finished?' do
    it 'returns true when all the master files are finished' do
      media_object = FactoryGirl.create(:media_object, parts: [FactoryGirl.create(:master_file, status_code: 'STOPPED'), FactoryGirl.create(:master_file, status_code: 'SUCCEEDED')])
      ingest_batch = IngestBatch.new(media_object_ids: [media_object.id], email: 'email@something.com')
      ingest_batch.finished?.should be true
    end
    
    # fix: adding master_files to media object parts is broken
    it 'returns false when one or more master files are not finished' do
       skip "Fix problems with this test"

       media_object = MediaObject.new(pid:'avalon:ingest-batch-test')
       media_object.add_relationship(:has_part, MasterFile.new(status_code: 'STOPPED'))
       media_object.parts << MasterFile.create(status_code: 'RUNNING')
       media_object.save(validate: false)
       ingest_batch = IngestBatch.new(media_object_ids: ['avalon:ingest-batch-test'], email: 'email@something.com')
       ingest_batch.finished?.should be true
    end
  end

  describe '#media_objects' do
    it 'returns an empty array if media_object_ids is nil' do
      n = IngestBatch.new
      n.media_objects.should == []
    end

    it 'returns an array of media objects based on ids passed in' do
      media_objects = (0..10).map{
          media_object = MediaObject.new
          media_object.save(validate: false)
          media_object 
        }
      ingest_batch = IngestBatch.new(media_object_ids:media_objects.map(&:id))
      ingest_batch.media_objects.should == media_objects
    end
  end

  describe '#email_sent?' do
    let(:ingest_batch){ IngestBatch.new }
    it 'returns true if email_sent is true' do
      ingest_batch.email_sent = true
      ingest_batch.email_sent?.should be true
    end
    it 'returns false if email_sent is false' do
      ingest_batch.email_sent = false
      ingest_batch.email_sent?.should be false
    end
  end
end
