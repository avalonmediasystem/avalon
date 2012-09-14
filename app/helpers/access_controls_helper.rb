require "role_controls"

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
    mediaobject = MediaObject.find(params[:id])
    
    unless mediaobject.access == "public" && mediaobject.is_published?
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
        raise Hydra::AccessDenied.new("You do not have sufficient access privileges to read this document, which has been marked private.", :read, params[:id])
      end
    end
  end

end
