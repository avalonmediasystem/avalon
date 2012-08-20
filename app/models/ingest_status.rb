class IngestStatus < ActiveRecord::Base
  attr_accessible :pid, :current_step, :complete
  
      # Return true if the step is current or prior to the parameter passed in
      # Defaults to false if the step is not recognized
      def completed?(step_name)
        current_index = HYDRANT_STEPS.index(step_name)
        last_index = HYDRANT_STEPS.index(current_step)
        
        status_flag = false
        unless (current_index.nil? or last_index.nil?)
          status_flag = (last_index >= current_index)
        end
        
        status_flag
      end

end
