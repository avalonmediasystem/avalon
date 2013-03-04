class Ability
	include CanCan::Ability
	include Hydra::Ability

	def create_permissions(user=nil, session=nil)
		if @user_groups.include? "collection_manager"
			can :manage, MediaObject
			can :manage, MasterFile
      can :inspect, MediaObject
    end
    
		if @user_groups.include? "group_manager"
		  can :manage, Admin::Group
      can :manage, Dropbox
		end
	end

  def custom_permissions(user=nil, session=nil)
    if @user_groups.exclude? "collection_manager"
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
    @user.username == mediaobject.avalon_uploader || @user_groups.include?("collection_manager")
  end  
end
