require 'hydrant/workflow/workflow_controller_behavior'

module Hydrant
  module Batch
    include Hydrant::Workflow::WorkflowControllerBehavior

    def self.ingest
      # Scans dropbox for new batch packages
      puts "New Batch job"
      new_packages = Hydrant::DropboxService.find_new_packages
    
      # Extracts package and process
      new_packages.each do |package|
        package.process do |fields, files|
          mediaobject = MediaObject.new
          mediaobject.workflow.origin = "batch"

          # Creates and processes MasterFiles
          package.file_list.each do |file_path|
            mf = MasterFile.new
            mf.container = mediaobject
            mf.setContent(File.open(file_path, 'rb'))
            if mf.save
              mf.process
            end
          end
                
          context = {mediaobject: mediaobject, parts: []}
          fus = create_workflow_step('file_upload')
          context = fus.execute context
        end
      end
    end
  end
end