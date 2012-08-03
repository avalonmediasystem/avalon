class Ability
	include CanCan::Ability
	include Hydra::Ability

	def create_permissions(user, session)
		if @user_groups.include? "archivist"
			can :create, Video
			can :create, VideoAsset
		end
	end

end
