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
    if !@user_groups.include? "archivist"
			can :read, MediaObject do |mediaobject|
        can?(:read, mediaobject) && (mediaobject.is_published? || can_read_unpublished(mediaobject))
      end
    end
	end

  def can_read_unpublished mediaobject
     current_user.username == mediaobject.avalon_uploader || RoleControls.user_roles(current_user).include?("archivist")
  end  
end
