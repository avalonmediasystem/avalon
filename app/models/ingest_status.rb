class IngestStatus < ActiveRecord::Base
  attr_accessible :pid, :current_step, :published
  before_save :reset_values
  
      # Return true if the step is current or prior to the parameter passed in
      # Defaults to false if the step is not recognized
      def completed?(step_name)
        status_flag = self.published || false

        unless self.published
          current_index = HYDRANT_STEPS.index(step_name)
          last_index = HYDRANT_STEPS.index(current_step)
        
          unless (current_index.nil? or last_index.nil?)
            status_flag = (last_index > current_index)
          end
        end
        
        status_flag
      end

      def current?(step_name)
        (step_name == self.current_step)
      end
      
      def active?(step_name)
        completed?(step_name) or current?(step_name)
      end
      
      protected
      def reset_values
        logger.debug "<< BEFORE_SAVE (IngestStatus) >>"
        logger.debug "<< current_step => #{self.current_step} >>"
        
        if published.nil?
          logger.debug "<< Default published flag = false >>"
          published = false
        end
        
        if current_step.nil?
          logger.debug "<< Default step = #{HYDRANT_STEPS.first.step} >>"
          current_step = HYDRANT_STEPS.first.step
        end
      end
end
