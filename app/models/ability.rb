class Ability
	include CanCan::Ability
	include Hydra::Ability

	def create_permissions(user, session)
		if @user_groups.include? "archivist"
			can :manage, MediaObject
			can :manage, MasterFile
    end
    
		if @user_groups.include? "admin_policy_object_editor"
		  can :manage, Admin::Group
		end
	end

  def custom_permissions(user, session)
    if @user_groups.exclude? "archivist"
      cannot :read, MediaObject do |mediaobject|
        (cannot :read, mediaobject.pid) || (not mediaobject.is_published? && not can_read_unpublished(mediaobject, user))
      end
    end
  end

  def can_read_unpublished(mediaobject, current_user)
    current_user.username == mediaobject.avalon_uploader || @user_groups.include?("archivist")
  end  
end
