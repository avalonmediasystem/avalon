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

module RightsMetadataExceptions
  def self.apply_to(mod)
    mod.class_eval do
      unless self == Hydra::Datastream::RightsMetadata
        include OM::XML::Document
        use_terminology(Hydra::Datastream::RightsMetadata) 
      end
      extend_terminology do |t|
        t.discover_groups(:proxy=>[:discover_access, :machine, :group])
        t.discover_users(:proxy=>[:discover_access, :machine, :person])
        t.read_groups(:proxy=>[:read_access, :machine, :group])
        t.read_users(:proxy=>[:read_access, :machine, :person])
        t.edit_groups(:proxy=>[:edit_access, :machine, :group])
        t.edit_users(:proxy=>[:edit_access, :machine, :person])
      end

      ["edit", "read", "discover"].each do |action|
        ["groups", "users"].each do |type|
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

      private

      def set_entities(permission, type, values, changeable)
        g = preserved(type, permission)
        (changeable - values).each do |entity|
          #Strip permissions from users not provided
          g[entity] = 'none'
        end
        values.each { |name| g[name] = permission.to_s}
        update_permissions(type.to_s=>g)
      end

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
