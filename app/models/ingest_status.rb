class IngestStatus < ActiveRecord::Base
  attr_accessible :pid, :current_step, :published
  
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

end
