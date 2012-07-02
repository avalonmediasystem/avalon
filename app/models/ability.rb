class Ability
	include CanCan::Ability
	include Hydra::Ability

	def custom_permissions(user, session)
		if @user_groups.include? "archivist"
			can :create, Video
		end
	end

  def enforce_create_permissions(opts={})
    if cannot? :create
      flash[:notice] = "You do not have sufficient priviledges to add resources"
      redirect_to root_path
    else 
      session[:viewing_context] = "create"
    end
  end
  
  def enforce_new_permissions(opts={})
    enforce_create_permissions(opts)
  end
end
