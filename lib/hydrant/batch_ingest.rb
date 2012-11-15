module Hydrant
  module Batch

    def self.ingest
      # Scans dropbox for new batch packages
      logger.info "============================================"
      logger.info "<< Starts scanning for new batch packages >>"
      
      new_packages = Hydrant::DropboxService.find_new_packages
      logger.info "<< Found #{new_packages.count} new packages >>"
      
      # Extracts package and process
      new_packages.each_with_index do |package, index|
        logger.info "<< Processing package #{index} >>"
        package.process do |fields, files|
          mediaobject = MediaObject.new
          mediaobject.workflow.origin = "batch"
          mediaobject.save(:validate => false)
          logger.info "<< Created MediaObject #{mediaobject.pid} >>"

          # Creates and processes MasterFiles
          package.file_list.each do |file_path|
            mf = MasterFile.new
            mf.container = mediaobject
            mf.setContent(File.open(file_path, 'rb'))
            if mf.save
              logger.info "<< Created & associated MasterFile #{mf.pid} >>"
              mf.process
            end
          end
                
          context = {mediaobject: mediaobject}
          context = HYDRANT_STEPS.get_step('file-upload').execute context
          logger.info "Done processing package #{index}"
        end
      end
    end

  end
end