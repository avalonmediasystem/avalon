class IngestBatch < ActiveRecord::Base

  attr_accessible :media_object_ids, :email
  serialize :media_object_ids, Array

  attr_reader :media_objects

  def finished?
    self.media_objects.all?{ |m| m.finished_processing? }
  end

  def media_objects
    return [] unless self.media_object_ids
    @media_objects ||= self.media_object_ids.map{ |id| MediaObject.find(id) }
  end

end