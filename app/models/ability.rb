class Ability
	include CanCan::Ability
	include Hydra::Ability

	def custom_permissions(user, session)
		if @user_groups.include? "archivist"
			can :create, Video
			can :create, VideoAsset
		end
	end

  def enforce_create_permissions(opts={})
    if cannot? :create, Video
      flash[:notice] = "You do not have sufficient priviledges to add items"
      redirect_to root_path
      return
    elsif cannot? :create, VideoAsset
      flash[:notice] = "You do not have sufficient priviledges to add files"
      redirect_to root_path
      return
    else 
      session[:viewing_context] = "create"
    end
  end
  
  def enforce_new_permissions(opts={})
    enforce_create_permissions(opts)
  end
end
