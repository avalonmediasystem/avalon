class BatchIngest
  include Hydrant::Workflow::WorkflowControllerBehavior
  
  def self.ingest
    # Scans dropbox for new batch packages
    new_packages = []
    
    # Extracts package and process
    new_packages.each do |package|
      mediaobject = MediaObject.new
      
      context = {mediaobject: mediaobject, parts: params[:parts]}
      fus = create_workflow_step('file_upload')
      context = fus.execute context
    
      context = {mediaobject: mediaobject, datastream: params[:media_object]}
      rds = create_workflow_step('resource-description')
      context = rds.execute context
    
      context = {mediaobject: mediaobject, access: params[:access]}
      acs = create_workflow_step('access-control')
      context = acs.execute context
    
      context = {mediaobject: mediaobject, masterfiles: params[:masterfile_ids]}
      struct_step = create_workflow_step('structure')
      context = struct_step.execute context
    end
  end
end