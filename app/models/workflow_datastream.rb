class WorkflowDatastream < ActiveFedora::SimpleDatastream
  self.field :status, :string
  self.field :last_completed_step, :string
  self.field :origin, :string

  def status= new_status
    self.status = case new_status
                  when 'published'
                    'published'
                  when 'unpublished'
                    'unpublished'
                  else
                    nil
                  end
  end

  def last_completed_step= active_step
    unless IngestWorkflow.exists? active_step
      logger.warn "Unrecognized step : #{active_step}"
    end
    
    # Set it anyways for now. Need to come up with a more robust warning
    # system down the road
    last_completed_step = active_step
  end 
  
  def origin= source
    unless ['batch', 'web', 'console'].contains? source
      logger.warn "Unrecognized origin : #{source}"
      origin = 'unknown'
    else
      origin = source
    end
  end
end
