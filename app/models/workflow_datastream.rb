# --- BEGIN LICENSE_HEADER BLOCK ---
# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class WorkflowDatastream < ActiveFedora::OmDatastream
  before_save :reset_values

  set_terminology do |t|
    t.root(path: 'workflow')
    
    t.last_completed_step(path: 'last_completed_step')
    t.published(path: 'published')
    t.origin(path: 'origin')
  end

  def published?
    published.first.eql? true.to_s
  end

  def published= publication_status
     update_values({[{:published=>"0"}]=>{"0"=>publication_status.to_s}})
  end

  def last_completed_step= active_step
    active_step = active_step.first if active_step.is_a? Array
    unless HYDRANT_STEPS.exists? active_step
      Rails.logger.warn "Unrecognized step : #{active_step}"
    end
    
    # Set it anyways for now. Need to come up with a more robust warning
    # system down the road
    update_values({[{:last_completed_step=>"0"}]=>{"0"=>active_step}})
  end 
  
  def origin= source
    unless ['batch', 'web', 'console'].include? source
      Rails.logger.warn "Unrecognized origin : #{source}"
      update_values({[{:origin=>"0"}]=>{"0"=>"unknown"}})
    else
      update_values({[{:origin=>"0"}]=>{"0"=>source}})
    end
  end

      # Return true if the step is current or prior to the parameter passed in
      # Defaults to false if the step is not recognized
      def completed?(step_name)
        status_flag = published? || false
        unless published?
          step_index = HYDRANT_STEPS.index(step_name)
          current_index = HYDRANT_STEPS.index(step_name)
          last_index = HYDRANT_STEPS.index(last_completed_step.first)
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
                    (last_completed_step.first == previous_step.step)
                  else
                    false
                  end

        current
      end
      
      def active?(step_name)
        completed?(step_name) or current?(step_name)
      end

      # Advance should recognize that a step is invalid and respond by 
      # defaulting to the first known step. If you are already on the last
      # step then don't advance any further. There's a potential for silently
      # failing here but this is a first pass only
      def advance
	lcs = (last_completed_step.is_a? Array) ? last_completed_step.first : last_completed_step

	if (lcs.blank? or not HYDRANT_STEPS.exists?(lcs))
	  Rails.logger.warn "<< Step #{lcs} invalid, defaulting to first step >>"
	  self.last_completed_step = HYDRANT_STEPS.first.step
	elsif (not HYDRANT_STEPS.last?(lcs))
	  next_step = HYDRANT_STEPS.next(lcs).step
	  Rails.logger.debug "<< Advancing to the next step - #{next_step} >>"
          self.last_completed_step = next_step 
        end
      end

      def publish
        self.last_completed_step = HYDRANT_STEPS.last.step 
        self.published = true.to_s
      end
      
  def update_status(active_step=nil)
      Rails.logger.debug "<< UPDATE_INGEST_STATUS >>"
      active_step = active_step || last_completed_step.first
      Rails.logger.debug "<< COMPLETED : #{completed?(active_step)} >>"

      if current?(active_step) and not published?
        advance
      end

      if HYDRANT_STEPS.last? active_step and completed? active_step
        publish
      end
      Rails.logger.debug "<< PUBLISHED : #{published?} >>"
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.workflow do
        xml.last_completed_step '' 
        xml.published false.to_s
        xml.origin 'unknown' 
      end
    end
    
    builder.doc
  end

  def to_solr(solr_doc=Hash.new, opts = {})
    super(solr_doc, opts)

    solr_value = case last_completed_step.first
    when blank?
      'New'
    when 'preview'
      'Completed'
    else
      'In progress'
    end
    # Compatible with both Solrizer 2.x and 3.x
    mapper = Solrizer.respond_to?(:default_field_mapper) ? Solrizer.default_field_mapper : Solrizer::FieldMapper::Default.new

    solr_doc.merge!(mapper.solr_name('workflow_status',:facetable) => solr_value)
    published_value = published? ? 'Published' : 'Unpublished'
    solr_doc.merge!(mapper.solr_name('workflow_published',:facetable) => published_value)
  end

      protected
      def reset_values
        Rails.logger.debug "<< BEFORE_SAVE (IngestStatus) >>"
        Rails.logger.debug "<< last_completed_step => #{last_completed_step} >>"
        
        if published.nil?
          Rails.logger.debug "<< Default published flag = false >>"
          published = false
        end
        
        if last_completed_step.nil?
          Rails.logger.debug "<< Default step = #{HYDRANT_STEPS.first.step} >>"
          last_completed_step = HYDRANT_STEPS.first.step
        end
      end

end
