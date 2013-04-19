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
		if @user_groups.include? "collection_manager"
			can :manage, MediaObject
			can :manage, MasterFile
      can :inspect, MediaObject
      can :manage, Dropbox
    end
    
		if @user_groups.include? "group_manager"
		  can :manage, Admin::Group
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
