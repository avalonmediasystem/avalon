require 'hydrant/dropbox'

  class FileUploadStep < Hydrant::Workflow::BasicStep
    def initialize(step = 'file-upload', title = "Manage file(s)", summary = "Associated bitstreams", template = 'file_upload')
      super
    end

    # For file uploads the process of setting the context is easy. We
    # just need to ask the dropbox if there are any files. If so load
    # them into a variable that can be referred to later
    def before_step context
       dropbox_files = Hydrant::DropboxService.all
       context[:dropbox_files] = dropbox_files 
       context
    end

    def after_step context
       context
    end

    def execute context
         logger.debug "<< Processing FILE-UPLOAD step >>"
       update_master_files context[:mediaobject], context[:parts] 
       unless context[:mediaobject].parts.empty?
           media = context[:mediaobject]
         media.format = media.parts.first.media_type
         media.save(validate: false)
         context[:mediaobject] = media
       end

       context
    end

  # Passing in an ordered array of values update the master files below a
  # MediaObject. Accepted hash keys are
  #
  # remove - Set to true to delete this item
  # label - Display label in the interface
  # pid - Identifier for the masterFile to help with mapping
  def update_master_files(mediaobject, files = [])
        logger.debug "<< files => #{files} >>"
        if not files.blank?
          files.each do |part|
            logger.debug "<< #{part} >>"
            selected_part = nil
            mediaobject.parts.each do |current_part|
              selected_part = current_part if current_part.pid == part[:pid]
            end
            next unless not selected_part.blank?

            if part[:remove]
              logger.info "<< Deleting master file #{part[:pid]} from the system >>"
              selected_part.delete
            else
              selected_part.label = part[:label]
              selected_part.save
            end
          end
        end
  end

  end
