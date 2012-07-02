module AccessControlsHelper
  def enforce_create_permissions(opts={})
    puts "in enforce_create_permissions"
    if cannot? :create, Video
      flash[:notice] = "You do not have sufficient priviledges to add resources"
      redirect_to root_path
    else
      session[:viewing_context] = "create"
    end
  end

  def enforce_new_permissions(opts={})
    puts "in enforce_new_permissions"
    enforce_create_permissions(opts)
  end
end
