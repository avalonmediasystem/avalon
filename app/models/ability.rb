class Ability
	include CanCan::Ability
	include Hydra::Ability

	def custom_permissions(user, session)
		if @user_groups.include? "archivist"
			can :create, Video
		end
	end
end
