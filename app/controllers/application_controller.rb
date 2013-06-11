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

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  
  # Adds Hydra behaviors into the application controller 
  include Hydra::Controller::ControllerBehavior
  include AccessControlsHelper

  layout 'avalon'
  
  # Please be sure to implement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  protect_from_forgery
  
  before_filter :trap_session_information if 
    (Rails.env.development? or Rails.env.test?)
  after_filter :set_access_control_headers
  
  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end
  
  def trap_session_information
    logger.debug "<< CURRENT SESSION INFORMATION >>"
    logger.debug session.inspect
  end


  # To be used with CanCan and load_and_authorize_resource (macro loads and sets instance variable @model_name)
  # POST /collections?media_object_ids=1,2,3,4
  # POST /collections?subcollection_ids=1,2,3,4
  # @collection.media_objects and @collection.subcollection_ids are pre-loaded
  # before controller#create, controller#update, controller#edit
  def load_and_authorize_nested_models
    model_name       = controller_name.classify.downcase
    model            = instance_variable_get "@#{model_name}"

    params[model_name.to_sym].each do |name, value|
      match = /(.+)_ids$/.match(name).try :captures
      if match
        association_ids        = value
        association_name       = match.first
        association_klass      = association_name.classify.constantize
        association_collection = association_ids.split(',').map do |association_id|
          next if ! association_id.include?(':')
          association = association_klass.find(association_id)
          authorize! :read, association
        end.compact

        model.clear_relationship(:has_collection_member)
        association_collection.each do |association| 
          model.add_relationship(:has_collection_member, "info:fedora/#{association.pid}")
        end
        
        model.send("#{association_name.pluralize}=".to_sym, association_collection)
      end
    end if params[model_name.to_sym]
  end
end
