class Ability
	include CanCan::Ability
	include Hydra::Ability

	def create_permissions(user, session)
		if @user_groups.include? "archivist"
			can :manage, MediaObject
			can :create, MasterFile
		end
		if @user_groups.include? "admin_policy_object_editor"
		  can :manage, Admin::Group
		end
	end

end
