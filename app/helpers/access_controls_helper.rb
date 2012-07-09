module AccessControlsHelper
  def enforce_create_permissions(opts={})
    if current_user.nil? 
      flash[:notice] = "You need to login to add resources"
      redirect_to new_user_session_path
    elsif cannot? :create, Video
      flash[:notice] = "You do not have sufficient privileges to add resources"
      redirect_to root_path
    else
      session[:viewing_context] = "create"
    end
  end

  def enforce_new_permissions(opts={})
    enforce_create_permissions(opts)
  end
end
