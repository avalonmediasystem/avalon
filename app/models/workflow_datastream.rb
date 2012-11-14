class WorkflowDatastream < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(path: 'workflow')
    
    t.last_completed_step(path: 'last_completed_step')
    t.published(path: 'published')
    t.origin(path: 'origin')
  end

  def published?
    published.eql? 'published'
  end

  def published= publication_status
     published = publication_status ? 'published' : 'unpublished'
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

 	

      # Return true if the step is current or prior to the parameter passed in
      # Defaults to false if the step is not recognized
      def completed?(step_name)
        status_flag = self.published || false
        unless self.published
          current_index = HYDRANT_STEPS.index(step_name)
          last_index = HYDRANT_STEPS.index(current_step)
          unless (current_index.nil? or last_index.nil?)
            status_flag = (last_index >= current_index)
          end
        end
        status_flag
      end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.workflow do
        xml.last_completed_step 
        xml.published 'unpublished'
        xml.origin 'unknown' 
      end
    end
    
    builder.doc
  end

  def to_solr(solr_doc=SolrDocument.new)
    super(solr_doc)

    case self.last_completed_step.first
    when ''
      solr_doc.merge!(:workflow_status_facet => "New")
    when 'preview'
      solr_doc.merge!(:workflow_status_facet => "Completed")
    default
      solr_doc.merge!(:workflow_status_facet => "In progress")
    end
    solr_doc.merge!(:workflow_published_facet => self.published.first.capitalize)
    solr_doc.merge!(:workflow_source_facet => self.origin.first.capitalize)
  end

end
