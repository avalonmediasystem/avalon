class WorkflowDatastream < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(path: 'workflow')
    
    t.status(path: 'status')
    t.last_completed_step(path: 'last_completed_step')
    t.published(path: 'published')
    t.origin(path: 'origin')
  end

  def status= new_status
    status = case new_status
                  when 'published'
                    'published'
                  when 'unpublished'
                    'unpublished'
                  else
                    nil
                  end
  end

  def last_completed_step= active_step
    unless HYDRANT_STEPS.exists? active_step
      logger.warn "Unrecognized step : #{active_step}"
    end
    
    # Set it anyways for now. Need to come up with a more robust warning
    # system down the road
    last_completed_step = active_step
  end 
  
  def origin= source
    unless ['batch', 'web', 'console'].include? source
      logger.warn "Unrecognized origin : #{source}"
      origin = 'unknown'
    else
      origin = source
    end
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.workflow do
        xml.status 'new'
        xml.last_completed_step 
        xml.published false.to_s
        xml.origin 
      end
    end
  end

end
