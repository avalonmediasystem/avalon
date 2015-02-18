# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

class R2GroupMigration < ActiveRecord::Migration
  def up
    if Admin::Group.exists?("collection_manager")
      # Start by looking for an existing manager group and failing the 
      # migration until it is dealt with
      if Admin::Group.exists?("manager")
        puts "WARNING: You already have a manager group"
        raise ActiveRecord::ConfigurationError
      end

      # Get the list of collection managers and create a new manager group
      # for them to exist under
      r1_managers = Admin::Group.find("collection_manager")
      Admin::Group.create(name: 'manager')
      r2_managers = Admin::Group.find('manager')
      r2_managers.users += r1_managers.users 
      r2_managers.save

      # Finally if all goes well we delete the collection_manager group
      r1_managers.delete
    end
    
    # Now test for the existance of the administrator group. If it does not
    # exist we assume that the first user in the group_manager list should
    # be promoted
    unless Admin::Group.exists?('administrator')
      Admin::Group.create(name: 'administrator')
      admins = Admin::Group.find('administrator') 
      default_admin = Admin::Group.find('group_manager').users.first
      admins.users += [default_admin]
      admins.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
