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

	class AccessControlStep < Avalon::Workflow::BasicStep
		def initialize(step = 'access-control', 
                   title = "Access Control", 
                   summary = "Who can access the item", 
                   template = 'access_control')
		  super
		end

		def execute context
		  mediaobject = context[:mediaobject]
      # TO DO: Implement me

      user = User.where({ Devise.authentication_keys.first => context[:user]}).first
      unless user.ability.can? :update_access_control, mediaobject
        return context
      end

      # Limited access stuff
      if context[:delete_group].present?
        groups = mediaobject.read_groups
        groups.delete context[:delete_group]
        mediaobject.read_groups = groups
      end 
      if context[:delete_user].present?
        users = mediaobject.read_users
        users.delete context[:delete_user]
        mediaobject.read_users = users
      end 

      if context[:commit] == "Add Group"
        groups = mediaobject.group_exceptions
        groups << context[:new_group] unless context[:new_group].blank?
        mediaobject.group_exceptions = groups
      elsif context[:commit] == "Add User"
        users = mediaobject.user_exceptions
        users << context[:new_user] unless context[:new_user].blank?
        mediaobject.user_exceptions = users
        puts "EXCEPTIONS #{MediaObject.find(mediaobject.pid).group_exceptions.inspect}"
      end

      mediaobject.access = context[:access] unless context[:access].blank? 

      mediaobject.hidden = context[:hidden] == "1"

      mediaobject.save
		  context
		end
	end
