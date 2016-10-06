class UpdateDependentPermalinksJob < ActiveJob::Base
  queue_as :update_dependent_permalinks
  def perform(media_object_id)
    MediaObject.find(media_object_id).update_dependent_permalinks
  end
end
