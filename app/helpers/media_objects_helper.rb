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

module MediaObjectsHelper
      # Quick and dirty solution to the problem of displaying the right template.
      # Quick and dirty also gets it done faster.
      def current_step_for(status=nil)
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
     
      # Based on the current context it will choose which class should be
      # applied to the display. If you are not using Twitter Bootstrap or
      # want different defaults then change them here.
      #
      # The context here is the media_object you are working with.
      def class_for_step(context, step)  
        logger.debug "<< Current step test is #{step} >>"
        logger.debug "<< Current? #{context.workflow.current?(step)} >>"
        logger.debug "<< Completed? #{context.workflow.completed?(step)} >>"

        css_class = case 
          # when context.workflow.current?(step)
          #   'nav-info'
          when context.workflow.completed?(step)
            'nav-success'
          else 'nav-disabled' 
          end

        css_class
     end
end
