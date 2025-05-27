# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

require File.join(Rails.root, "app/models/role_map")

module Avalon
  class RoleControls
    class RoleExists < StandardError
    end

    class UserRoleExists < StandardError
    end

    class RoleNotExist < StandardError
    end

    class UserRoleNotExist < StandardError
    end

    class << self
      def users(role)
        RoleMapper.whois(role)
      end

      def user_roles(user)
        RoleMapper.byname[user]
      end

      def roles
        RoleMapper.role_names
      end

      def role_exists? role
        roles.include? role
      end

      def assign_users(new_users, role)
        RoleMapper.update { |map| map[role] = new_users.reject { |u| u.blank? } }
      end

      def add_role(role)
        if RoleMapper.map[role].nil?
          RoleMapper.update { |map| map[role] = [] }
        else
          raise RoleExists, "Cannot add role \"#{role}\", it already exists"
        end
      end

      def remove_role(role)
        if RoleMapper.map[role].nil?
          raise RoleNotExist, "Cannot remove role \"#{role}\", it does not exist"
        else
          RoleMapper.update { |map| map.delete(role) }
        end
      end

      def remove_user_role(user, role)
        if RoleMapper.map[role].nil?
          raise RoleNotExist, "Cannot remove user-role \"#{user}\" - \"#{role}\", role does not exist"
        elsif !RoleMapper.map[role].include? user
          raise UserRoleExists, "Cannot remove user-role \"#{user}\" - \"#{role}\", relationship does not exist"
        else
          RoleMapper.update { |map| map[role].delete(user) }
        end
      end

      def add_user_role(user, role)
        if RoleMapper.map[role].nil?
          raise RoleNotExist, "Cannot add user \"#{user}\" to role \"#{role}\", role does not exist"
        elsif RoleMapper.map[role].include? user
          raise UserRoleExists, "Cannot add user \"#{user}\" to role \"#{role}\", relationship already exists"
        else
          RoleMapper.update { |map| map[role] << user }
        end
      end

      def save_changes
        # noop!
      end
    end
  end
end
