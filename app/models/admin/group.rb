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

require "role_controls"

class Admin::Group
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Dirty
  
  # For now this list is a hardcoded constant. Eventually it might be more flexible
  # as more thought is put into the process of providing a comment
  attr_accessor :name, :users
  validates :name, presence: {message: "Name is a required field"}

  def self.non_system_groups
    groups = all
    if Avalon::Configuration['groups'] && Avalon::Configuration['groups']['system_groups']
      system_groups = Avalon::Configuration['groups']['system_groups']
      groups.reject! { |g| system_groups.include? g.name }
    end
    groups
  end
 
  def self.all
    groups = [] 
    RoleControls.roles.each do |role|
      groups << Admin::Group.find(role)
    end
    groups
  end

  def self.find(name)
    if RoleControls.roles.include? name
      # Creates a new object that looks like an old object
      # Note that there's an issue: all attributes will appear changed
      group = self.new
      group.name = name
      group.users = RoleControls.users(name)
      group.new_record = false
      group.saved = true
      group
    else
      nil
    end
  end

  def self.exists? name
    RoleControls.role_exists? name
  end

  def self.create(attributes = nil)
    group = Admin::Group.new
    if attributes.present?
      group.name = attributes[:name]
      if self.exists? group.name
      end
    end

    if group.valid?
      group.save
    else 
      return false
    end
 
    group
  end
  
  def self.new 
    g = super
    g.new_record = true
    g
  end

  def self.abstract_class?
    return false
  end

  def self.arel_table
    @arel_table ||= Arel::Table.new(nil, nil)
  end

  def new_record?
    @new_record
  end

  def new_record= val
    @new_record = val
  end
  
  def initialize(attributes = {})
    @saved = false
    @users = []
    attributes.each do |k, v|
      send("#{k}=", v)
    end
  end

  # These are needed so ActiveModel::Dirty works
  # and Group behaves like an ActiveRecord model
  def name
    @name
  end

  def name=(value)
    attribute_will_change!('name') if name != value
    @previous_name = name
    @name = value
  end

  def name_changed?
    changed.include?('name')
  end
  
  def users
    @users
  end

  def users=(value)
    attribute_will_change!('users') if users != value
    @users = value
  end

  def users_changed?
    changed.include?('users')
  end
  
  def resources
    res = []
  end
  
  def id 
    @name
  end
  
  # Necessary hack so that form_for works with both :new and :edit
  def save
    if new_record? && valid? && !self.class.exists?(name) 
      RoleControls.add_role(name)
      RoleControls.save_changes
      @saved = true
    elsif !new_record? && valid?
      if name_changed? && !@previous_name.eql?(name)
        RoleControls.remove_role @previous_name
        RoleControls.add_role name
      end
      if users_changed?
        RoleControls.assign_users(users, name)
      end

      RoleControls.save_changes
      @saved = true
    elsif new_record? && valid? && self.class.exists?(name)
      errors.add(:name, "Group name already exists")
    else 
      @saved = false
    end 

    changed.clear if @saved 
    @saved
  end

  def delete 
    RoleControls.remove_role(name)
    RoleControls.save_changes
  end
  
  # Stub this method out so that form_for functions as expected for edit vs new
  # even though there is no database backing the Group model
  def persisted?
    @saved
  end
  
  def saved
    @saved
  end

  def saved= val 
    @saved = val
  end

end
