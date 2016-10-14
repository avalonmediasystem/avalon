class ExtractStillJob < ActiveJob::Base
  queue_as :extract_still
  def perform(id, options)
    return unless id
    mf = MasterFile.find(id)
    mf.extract_still(options)
  end
end
