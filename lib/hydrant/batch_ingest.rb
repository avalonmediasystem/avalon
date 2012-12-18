module Hydrant
  module Batch

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
          mediaobject = MediaObject.new(avalon_uploader: 'batch')
          mediaobject.workflow.origin = "batch"
          mediaobject.access = "restricted"
          mediaobject.edit_groups = ["archivist"]
          mediaobject.save(:validate => false)
          logger.debug "<< Created MediaObject #{mediaobject.pid} >>"

          files.each do |file_path|
            logger.debug file_path.inspect
            mf = MasterFile.new
            mf.container = mediaobject
            mf.setContent(File.open(file_path, 'rb'))
            if mf.save
              logger.debug "<< Created & associated MasterFile #{mf.pid} >>"
              mf.process
            end
          end

          context = {mediaobject: mediaobject}
          context = HYDRANT_STEPS.get_step('file-upload').execute context

          context = {mediaobject: mediaobject, media_object: fields}
          context = HYDRANT_STEPS.get_step('resource-description').execute context

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