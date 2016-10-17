require 'active_encode'

module ActiveEncodeJob
  module Core
    def error(master_file, exception)
      # add message here to update master file
      master_file.status_code = 'FAILED'
      master_file.error = exception.message
      master_file.save
    end
  end

  class Create < ActiveJob::Base
    include ActiveEncodeJob::Core
    queue_as :active_encode_create
    def perform(master_file_id, input, options)
      mf = MasterFile.find(master_file_id)
      encode = mf.encoder_class.new(input, options)
      unless encode.created?
        Rails.logger.info "Creating! #{encode.inspect} for MasterFile #{master_file_id}"
        mf.update_progress_with_encode!(encode.create!).save
        ActiveEncodeJob::Update.set(wait: 10.seconds).perform_later(master_file_id)
      end
    rescue StandardError => e
      error(mf, e)
    end
  end

  class Update < ActiveJob::Base
    include ActiveEncodeJob::Core  #I'm not sure if the error callback is really makes sense here!
    queue_as :active_encode_update
    def perform(master_file_id)
      Rails.logger.info "Updating encode progress for MasterFile: #{master_file_id}"
      mf = MasterFile.find(master_file_id)
      mf.update_progress!
      mf.save
      mf.reload
      ActiveEncodeJob::Update.set(wait: 10.seconds).perform_later(master_file_id) unless mf.finished_processing?
    rescue StandardError => e
      error(mf, e)
    end
  end
end
