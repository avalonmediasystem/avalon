# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class Ability
	include CanCan::Ability
	include Hydra::Ability

	def create_permissions(user=nil, session=nil)
		if @user_groups.include? "administrator"
			can :manage, MediaObject
			can :manage, MasterFile
      can :inspect, MediaObject
      can :manage, Dropbox
		  can :manage, Admin::Group
      can :manage, Collection
    end
    
		if @user_groups.include? "group_manager"
		  can :manage, Admin::Group
		end

		if @user_groups.include? "depositor"
		  can :create, MediaObject
		end
	end

  def custom_permissions(user=nil, session=nil)
    if @user_groups.exclude? "administrator"
      cannot :read, MediaObject do |mediaobject|
        (cannot? :read, mediaobject.pid) || 
          ((not mediaobject.published?) && 
           (not can_update(mediaobject)))
      end

      can :update, MediaObject do |mediaobject|
        is_member_of?(mediaobject.collection)
      end

      can :destroy, MediaObject do |mediaobject|
        can_destroy(mediaobject) 
      end

      can :update_access_control, MediaObject do |mediaobject|
        is_member_of?(mediaobject.collection) && !mediaobject.collection.depositors.include?(@user.username)
      end

      can :update_unit, Collection do |collection|
        collection.managers.include?(@user.username)
      end

      can :update_managers, Collection do |collection|
        collection.managers.include?(@user.username)
      end

      can :update_editors, Collection do |collection|
        collection.managers.include?(@user.username)
      end

      can :update_depositors, Collection do |collection|
        collection.managers.include?(@user.username) || collection.editors.include?(@user.username)
      end
    end
   
    can :read, Derivative do |derivative|
      can? :read, derivative.masterfile.mediaobject
    end
  end

  def is_member_of?(collection)
     @user_groups.include?("administrator") || 
       collection.managers.include?(@user.username) ||
       collection.editors.include?(@user.username) ||
       collection.depositors.include?(@user.username)
  end

  def can_destroy(mediaobject)
    # depositors can only destroy mediaobject if it's unpublished 
    is_member_of?(mediaobject.collection) && 
      ( !mediaobject.published? || 
        (!mediaobject.collection.depositors.include?(@user.username) && !mediaobject.collection.editors.include?(@user.username)) ) 
  end
end
