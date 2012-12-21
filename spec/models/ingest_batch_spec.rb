require 'spec_helper'

describe IngestBatch do
  it 'persists media object ids' do
    media_object_ids = [1,2,3]
    ingest_batch = IngestBatch.create(media_object_ids: media_object_ids)
    ingest_batch.reload
    ingest_batch.media_object_ids.should == media_object_ids
  end
  describe '#finished?' do
    it 'returns true when all the master files are finished' do
      media_object = MediaObject.new
      media_object.parts << MasterFile.new(status_code: ['STOPPED'])
      media_object.parts << MasterFile.new(status_code: ['SUCCEEDED'])
      media_object.save(validate: false)

      ingest_batch = IngestBatch.new(media_object_ids: ['changeme:1'], email: 'email@something.com')
      ingest_batch.finished?.should be_true
    end
    # fix: adding master_files to media object parts is broken
    # it 'returns false when one or more master files are not finished' do
    #   media_object = MediaObject.new(pid:'changeme:1')
    #   media_object.add_relationship(:has_part, MasterFile.new(status_code: ['STOPPED']))
    #   media_object.parts << MasterFile.create(status_code: ['RUNNING'])
    #   media_object.save(validate: false)
    #   ingest_batch = IngestBatch.new(media_object_ids: ['changeme:1'], email: 'email@something.com')
    #   ingest_batch.finished?.should be_false
    # end
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
      ingest_batch.email_sent?.should be_true
    end
    it 'returns false if email_sent is false' do
      ingest_batch.email_sent = false
      ingest_batch.email_sent?.should be_false
    end
  end
end