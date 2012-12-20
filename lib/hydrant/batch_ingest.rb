module Hydrant
  module Batch

    include Hydrant::Controller::ControllerBehavior

    def self.ingest
      # Scans dropbox for new batch packages
      logger.debug "============================================"
      logger.debug "<< Starts scanning for new batch packages >>"
      
      new_packages = Hydrant::DropboxService.find_new_packages
      logger.debug "<< Found #{new_packages.count} new packages >>"
      
      # Extracts package and process
      new_packages.each_with_index do |package, index|
        logger.debug "<< Processing package #{index} >>"

        package.process do |fields, files|
          # Creates and processes MasterFiles
          mediaobject = initialize_media_object('batch')
          mediaobject.workflow.origin = "batch"
          mediaobject.save(:validate => false)
          logger.debug "<< Created MediaObject #{mediaobject.pid} >>"

          # Simluate the uploading of the files using the workflow step so that
          # changes only have to be made in one place. This may mean some
          # refactoring of the master_file_controller class eventually.
          files.each do |file_path|
            mf = MasterFile.new
            mf.container = mediaobject
            mf.setContent(File.open(file_path, 'rb'))
            if mf.save
              logger.debug "<< Created and associated MasterFile #{mf.pid} >>"
              mf.process
            end
          end

          context = {mediaobject: mediaobject}
          context = HYDRANT_STEPS.get_step('file-upload').execute context

          context = {mediaobject: mediaobject, media_object: fields}
          context = HYDRANT_STEPS.get_step('resource-description').execute context

          # Here we need to skip the structure step and go straight to the
          # permissions. Structure is implicit from the order the files were
          # listed in the batch manifest
          #
          # Afterwards, if the auto-publish flag is true then publish the
          # media objects. In either case here is where the notifications
          # should take place
          if mediaobject.save
            logger.debug "Done processing package #{index}"
          else 
            logger.debug "Problem saving MediaObject"
          end
        end
      end
    end
    
  end
end
