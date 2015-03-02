# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

module Avalon
  module Controller
    module ControllerBehavior
      def self.included(base)
        base.extend(ClassMethods)
      end

      def deliver_content
        @obj = ActiveFedora::Base.find(params[:id], :cast => true)
        if can? :inspect, @obj
          ds = @obj.datastreams[params[:datastream]]
          if ds.nil? or ds.new?
            render :text => 'Not Found', :status => :not_found
          else
            render :text => ds.content, :content_type => ds.mimeType
          end
        else
          render :text => 'Unauthorized', :status => :unauthorized
        end
      end

    end
  end
end
