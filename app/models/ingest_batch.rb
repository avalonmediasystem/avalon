# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

#  attr_accessible :media_object_ids, :name, :email, :email_sent
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
