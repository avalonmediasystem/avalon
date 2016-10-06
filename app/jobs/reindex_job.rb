class ReindexJob < ActiveJob::Base
  queue_as :reindex
  def perform(ids)
    ids.each do |id|
      ActiveFedora::Base.find(id, cast: true).update_index
    end
  end
end
