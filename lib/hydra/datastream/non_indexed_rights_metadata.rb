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

module Hydra
  module Datastream
    class NonIndexedRightsMetadata < Hydra::Datastream::RightsMetadata   
      include Hydra::AccessControls::Visibility 

      ACTIONS = ["edit", "read", "discover"]
      TYPES = ["groups", "users"]
      ACTIONS.each do |action|
        TYPES.each do |type|
          define_method("#{action}_#{type}") do
            type_method = "individuals" if type == "users"
            type_method ||= type
            send(type_method).map {|k, v| k if v == action}.compact
          end
          define_method("#{action}_#{type}=") do |arg|
            send("set_#{action}_#{type}", arg, send("#{action}_#{type}"))
          end
          define_method("#{action}_#{type}_string") do
            send("#{action}_#{type}").join(', ')
          end
          define_method("#{action}_#{type}_string=") do |arg|
            send("#{action}_#{type}=", arg.split(/[\s,]+/))
          end
          define_method("set_#{action}_#{type}") do |arg1, arg2|
            type_sym = :person if type == "users"
            type_sym ||= type.singularize.to_sym
            send("set_entities", action.to_sym, type_sym, arg1, arg2)
          end
        end
      end  

      def to_solr(solr_doc=Hash.new)
        return solr_doc
      end

  def group_exceptions= excepts
    if access == 'limited'
      self.read_groups = excepts
    end
    self.method_missing(:group_exceptions=, excepts)
  end

  def user_exceptions= excepts
    if access == 'limited'
      self.read_users = excepts
    end
    self.method_missing(:user_exceptions=, excepts)
  end

  def access
    if self.visibility == 'private' && (self.read_groups.any? || self.read_users.any?)
      'limited'
    else
      self.visibility
    end
  end

  def access= access_level
    return if access_level == access
    if access_level == 'limited'
      self.visibility = 'private'
      self.read_users = user_exceptions
      self.read_groups = group_exceptions
    else
      self.read_users = []
      self.read_groups = []
      self.visibility = access_level
    end
  end

  def local_group_exceptions
    group_exceptions.select {|g| Admin::Group.exists? g}
  end

  def virtual_group_exceptions
    group_exceptions - local_group_exceptions
  end

      def hidden= value
        groups = self.discover_groups
        if value
          groups << "nobody"
        else
          groups.delete "nobody"
        end
        self.discover_groups = groups.uniq
      end
    
      def hidden?
        discover_groups.include? "nobody"
      end
    
      ## Copied from RightsMetadata mixins, would be nice to not have to do this 
      ## Updates those permissions that are provided to it. Does not replace any permissions unless they are provided
      # @example
      #  obj.permissions= [{:name=>"group1", :access=>"discover", :type=>'group'},
      #  {:name=>"group2", :access=>"discover", :type=>'group'}]
      def permissions=(params)
        perm_hash = {'person' => individuals, 'group'=> groups}

        params.each do |row|
          if row[:type] == 'user' || row[:type] == 'person'
            perm_hash['person'][row[:name]] = row[:access]
          elsif row[:type] == 'group'
            perm_hash['group'][row[:name]] = row[:access]
          else
            raise ArgumentError, "Permission type must be 'user', 'person' (alias for 'user'), or 'group'"
          end
        end
        
        update_permissions(perm_hash)
      end


      ## Returns a list with all the permissions on the object.
      # @example
      #  [{:name=>"group1", :access=>"discover", :type=>'group'},
      #  {:name=>"group2", :access=>"discover", :type=>'group'},
      #  {:name=>"user2", :access=>"read", :type=>'user'},
      #  {:name=>"user1", :access=>"edit", :type=>'user'},
      #  {:name=>"user3", :access=>"read", :type=>'user'}]
      def _permissions
        (groups.map {|x| {:type=>'group', :access=>x[1], :name=>x[0] }} + 
          individuals.map {|x| {:type=>'user', :access=>x[1], :name=>x[0]}})

      end
   
 #TODO add visibility and associated methods
      def public_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "read")
      end

      def registered_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED}, "read")
        permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "none")
      end

      def private_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED}, "none")
        permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "none")
      end
 
private 

      # @param  permission either :discover, :read or :edit
      # @param  type either :person or :group
      # @param  values  Values to set
      # @param  changeable Values we are allowed to change
      def set_entities(permission, type, values, changeable)
        g = preserved(type, permission)
        (changeable - values).each do |entity|
          #Strip permissions from users not provided
          g[entity] = 'none'
        end
        values.each { |name| g[name] = permission.to_s}
        update_permissions(type.to_s=>g)
      end

      # Get those permissions we don't want to change
      def preserved(type, permission)
        case permission
        when :edit
          g = {}
        when :read
          Hash[quick_search_by_type(type).select {|k, v| v == 'edit'}]
        when :discover
          Hash[quick_search_by_type(type).select {|k, v| v == 'discover'}]
        end
      end
    end
  end
end
