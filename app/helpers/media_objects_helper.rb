module MediaObjectsHelper
      # Quick and dirty solution to the problem of displaying the right template.
      # Quick and dirty also gets it done faster.
      def current_step_for(status=nil)
        logger.debug "<< CURRENT_STEP_FOR >>"
        logger.debug "<< STEP => #{status} >>"
        
        if status.nil?
          status = HYDRANT_STEPS.first
        end
        
        HYDRANT_STEPS.template(status)
      end
      
      def next_step_for(status)
        unless HYDRANT_STEPS.exists?(status)
          status = HYDRANT_STEPS.first.step
        end
        HYDRANT_STEPS.next(status)
      end

      def previous_step_for(status)
        unless HYDRANT_STEPS.exists?(status)
          status = HYDRANT_STEPS.first.step
        end
        HYDRANT_STEPS.previous(status)
      end  
      
end


