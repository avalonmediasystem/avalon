class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller  
# Adds Hydra behaviors into the application controller 
  include Hydra::Controller::ControllerBehavior

  include AccessControlsHelper

  def layout_name
   'hydrant'
  end

  # Please be sure to implement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  protect_from_forgery
  
  after_filter :set_access_control_headers
  
  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end
end
