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

module AccessControlsHelper
  def enforce_create_permissions(opts={})
    if current_user.nil? 
      flash[:notice] = "You need to login to add resources"
      redirect_to new_user_session_path
    elsif cannot? :create, MediaObject
      flash[:notice] = "You do not have sufficient privileges to add resources"
      redirect_to root_path
    else
      session[:viewing_context] = "create"
    end
  end

  def enforce_new_permissions(opts={})
    enforce_create_permissions(opts)
  end
  
  # Controller "before" filter for enforcing access controls on edit actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_edit_permissions(opts={})
    logger.debug("Enforcing edit permissions")
    load_permissions_from_solr
    if current_user.nil? 
      flash[:notice] = "You need to login to edit resources"
      redirect_to new_user_session_path
    elsif !can? :edit, params[:id]
      session[:viewing_context] = "browse"
      flash[:notice] = "You do not have sufficient privileges to edit this document. You have been redirected to the read-only view."
      redirect_to :action=>:show
    else
      session[:viewing_context] = "edit"
    end
  end  
  
  # Controller "before" filter for enforcing access controls on show actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_show_permissions(opts={})
    # load_permissions_from_solr
    # Add some robust handling in case the ID does not exist so that an
    # exception is not thrown immediately
    return if not MediaObject.exists?(params[:id])

    mediaobject = MediaObject.find(params[:id])
    unless mediaobject.access == "public" && mediaobject.published?
      # TODO: uncomment when we use embargo
      # if @permissions_solr_document["embargo_release_date_dt"] 
      #   embargo_date = Date.parse(@permissions_solr_document["embargo_release_date_dt"].split(/T/)[0])
      #   if embargo_date > Date.parse(Time.now.to_s)
      #     unless current_user && can?(:edit, params[:id])
      #       raise Hydra::AccessDenied.new("This item is under embargo.  You do not have sufficient access privileges to read this document.", :edit, params[:id])
      #     end
      #   end
      # end
      if cannot?(:read, mediaobject)
        raise Hydra::AccessDenied.new("You do not have sufficient access privileges to read this document.", :read, mediaobject.pid)
      end
    end
  end

end
