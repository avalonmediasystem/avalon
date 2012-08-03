class Ability
	include CanCan::Ability
	include Hydra::Ability

	def custom_permissions(user, session)
		if @user_groups.include? "archivist"
			can :create, Video
			can :create, VideoAsset
		end
		if @user_groups.include? "admin_policy_object_editor"
		  can :manage, Admin::Group
		end
	end
end
