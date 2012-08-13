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
    
    def roles
      RoleMapper.role_names
    end
    
    def role_exists? role
      roles.include? role
    end 
    
    def assign_users(new_users, role)
      RoleMapper.map[role] = new_users.reject { |u| u.empty? }
    end
    
    def add_role(role)
      if RoleMapper.map[role].nil?
        RoleMapper.map[role] = []
      else
        raise RoleExists, "Cannot add role \"#{role}\", it already exists"
      end
    end
  
    def remove_role(role)
      if RoleMapper.map[role].nil?
        raise RoleNotExist, "Cannot remove role \"#{role}\", it does not exist"
      else
        RoleMapper.map.delete(role)
      end
    end
  
    def remove_user_role(user, role)
      if RoleMapper.map[role].nil?
        raise RoleNotExist, "Cannot remove user-role \"#{user}\" - \"#{role}\", role does not exist"
      elsif !RoleMapper.map[role].include? user
        raise UserRoleExists, "Cannot remove user-role \"#{user}\" - \"#{role}\", relationship does not exist"
      else
        RoleMapper.map[role].delete(user)
      end
    end
  
    def add_user_role(user, role)
      if RoleMapper.map[role].nil?
        raise RoleNotExist, "Cannot add user \"#{user}\" to role \"#{role}\", role does not exist"
      elsif RoleMapper.map[role].include? user
        raise UserRoleExists, "Cannot add user \"#{user}\" to role \"#{role}\", relationship already exists"
      else
        RoleMapper.map[role] << user
      end
    end
  
    def save_changes
      doc = ""
      RoleMapper.map.each_pair do |k, v|
        usrarr = v.join("\r\n  - ")
        doc += "#{k}:\r\n  - #{usrarr}\r\n"
      end
      
      File.open(File.join(Rails.root, "config/role_map_#{Rails.env}.yml"), "w") {|f| f.write(doc) }
    end
  end
end