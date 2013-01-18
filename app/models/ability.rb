class Ability
	include CanCan::Ability
	include Hydra::Ability

	def create_permissions(user=nil, session=nil)
		if @user_groups.include? "archivist"
			can :manage, MediaObject
			can :manage, MasterFile
    end
    
		if @user_groups.include? "admin_policy_object_editor"
		  can :manage, Admin::Group
		end
	end

  def custom_permissions(user=nil, session=nil)
    if @user_groups.exclude? "archivist"
      cannot :read, MediaObject do |mediaobject|
        (cannot? :read, mediaobject.pid) || 
          ((not mediaobject.published?) && 
           (not can_read_unpublished(mediaobject)))
      end
    end
   
    can :read, Derivative do |derivative|
      can? :read, derivative.masterfile.mediaobject
    end
  end

  def can_read_unpublished(mediaobject)
    @user.username == mediaobject.avalon_uploader || @user_groups.include?("archivist")
  end  
end
