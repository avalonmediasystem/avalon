# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

require 'avalon/role_controls'

module Admin
  class Group
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::Dirty

    # For now this list is a hardcoded constant. Eventually it might be more flexible
    # as more thought is put into the process of providing a comment
    attr_accessor :name, :users
    validates :name, :presence => true
    validates :name, format: {
      without: /[\.;%\/]/,
      message: "must not contain any of the following: . ; % /" }

    def self.non_system_groups
      groups = all
      if system_groups = Settings.groups.system_groups
        groups.reject! { |g| system_groups.include? g.name }
      end
      groups
    end

    def self.all
      groups = []
      Avalon::RoleControls.roles.each do |role|
        groups << Admin::Group.find(role)
      end
      groups
    end

    def self.find(name)
      if Avalon::RoleControls.roles.include? name
        # Creates a new object that looks like an old object
        group = self.new
        group.ignoring_changes do
          group.name = name
          group.users = Avalon::RoleControls.users(name)
          group.new_record = false
          group.saved = true
        end
        group
      else
        nil
      end
    end

    def self.exists? name
      Avalon::RoleControls.role_exists? name
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
      attribute_will_change!('name') if name != value and !@ignoring_changes
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
      attribute_will_change!('users') if users != value and !@ignoring_changes
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
    # FIXME This method is gnarly and doesn't allow everything that it should
    def save
      if new_record? && valid? && !self.class.exists?(name)
        Avalon::RoleControls.add_role(name)
        Avalon::RoleControls.save_changes
        @saved = true
      elsif !new_record? && valid?
        if name_changed? && !@previous_name.eql?(name)
          Avalon::RoleControls.remove_role @previous_name
          Avalon::RoleControls.add_role name
          Avalon::RoleControls.assign_users(users, name)
        end
        if users_changed?
          Avalon::RoleControls.assign_users(users, name)
        end

        Avalon::RoleControls.save_changes
        @saved = true
      elsif new_record? && valid? && self.class.exists?(name)
        errors.add(:name, "Group name already exists")
      else
        @saved = false
      end

      changed.clear if @saved
      @saved
    end

    alias_method :save!, :save

    def delete
      Avalon::RoleControls.remove_role(name)
      Avalon::RoleControls.save_changes
    end

    def ignoring_changes
      begin
        @ignoring_changes = true
        yield self
      ensure
        @ignoring_changes = false
      end
      return self
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

    # Check to see if the name is static based on its inclusion in the system
    # group. This is a workaround for the bug that breaks the system whenever
    # a system group is renamed.
    def self.name_is_static? group_name
      Settings.groups.system_groups.include? group_name
    end
  end
end
