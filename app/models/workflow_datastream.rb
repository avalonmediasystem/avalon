class WorkflowDatastream < ActiveFedora::NokogiriDatastream
  before_save :reset_values

  set_terminology do |t|
    t.root(path: 'workflow')
    
    t.last_completed_step(path: 'last_completed_step')
    t.published(path: 'published')
    t.origin(path: 'origin')
  end

  def published?
    @published.eql? 'published'
  end

  def published= publication_status
     @published = publication_status ? 'published' : 'unpublished'
  end

  def last_completed_step= active_step
    active_step = active_step.first if active_step.is_a? Array
    unless HYDRANT_STEPS.exists? active_step
      logger.warn "Unrecognized step : #{active_step}"
    end
    
    # Set it anyways for now. Need to come up with a more robust warning
    # system down the road
    @last_completed_step = [active_step]
  end 
  
  def origin= source
    unless ['batch', 'web', 'console'].include? source
      logger.warn "Unrecognized origin : #{source}"
      @origin = 'unknown'
    else
      @origin = source
    end
  end

      # Return true if the step is current or prior to the parameter passed in
      # Defaults to false if the step is not recognized
      def completed?(step_name)
        status_flag = self.published? || false

        unless self.published?
          step_index = HYDRANT_STEPS.index(step_name)
          current_index = HYDRANT_STEPS.index(last_completed_step)
          unless (current_index.nil? or last_index.nil?)
            status_flag = (last_index >= current_index)
          end
        end
        status_flag
      end

      # Current can be true if the last_completed_step is defined as the
      # step prior to the current one. If the step given is the first and
      # the value of last_completed_step is blank then it is also true
      #
      # Otherwise assume the result should be false because you are on a
      # different step
      def current?(step_name)
        current = case
                  when HYDRANT_STEPS.first?(step_name)
                    last_completed_step.first.empty?
                  when HYDRANT_STEPS.exists?(step_name)
                    previous_step = HYDRANT_STEPS.previous(step_name)
                    (last_completed_step == previous_step.step)
                  else
                    false
                  end

        current
      end
      
      def active?(step_name)
        completed?(step_name) or current?(step_name)
      end

      def advance
        self.last_completed_step = HYDRANT_STEPS.next(self.last_completed_step).step
      end

      def publish
        self.last_completed_step = "published"
        self.published = true
      end
      
  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.workflow do
        xml.last_completed_step '' 
        xml.published 'false'
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

      protected
      def reset_values
        logger.debug "<< BEFORE_SAVE (IngestStatus) >>"
        logger.debug "<< last_completed_step => #{self.last_completed_step} >>"
        
        if published.nil?
          logger.debug "<< Default published flag = false >>"
          self.published = false
        end
        
        if last_completed_step.nil?
          logger.debug "<< Default step = #{HYDRANT_STEPS.first.step} >>"
          self.last_completed_step = HYDRANT_STEPS.first.step
        end
      end



end
