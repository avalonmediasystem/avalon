# USAGE:
#  In the batch ingest task:
#  IngestBatch.create( media_object_ids: @media_objects.map(&:id), email: email )
#
#  In master file update:
#  ingest_batch = IngestBatch.find_ingest_batch_by_media_object_id( @master_file.media_object.id )
#  if ingest_batch && ! ingest_batch.email_sent? && ingest_batch.finished?
#    IngestBatchMailer.status_email(ingest_batch.id).deliver
#    ingest_batch.email_sent = true
#  end

class IngestBatch < ActiveRecord::Base

  attr_accessible :media_object_ids, :email, :email_sent
  serialize :media_object_ids

  attr_reader :media_objects

  def finished?
    self.media_objects.all?{ |m| m.finished_processing? }
  end

  def email_sent?
    self.email_sent
  end

  def media_objects
    return [] unless self.media_object_ids
    @media_objects ||= self.media_object_ids.map{ |id| MediaObject.find(id) }
  end

  # this is a temporary method until we can talk about adding
  # ingest_batch_id to media object
  def self.find_ingest_batch_by_media_object_id( id )
    IngestBatch.all.find{ |ib| ib.media_object_ids.include?( id )}
  end
end