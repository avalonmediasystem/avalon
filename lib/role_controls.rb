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
