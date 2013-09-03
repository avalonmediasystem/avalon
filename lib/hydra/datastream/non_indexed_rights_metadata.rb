module Hydra
  module Datastream
    class NonIndexedRightsMetadata < Hydra::Datastream::RightsMetadata    

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

      # Default access for new items 
      # Copied from MediaObject, would be nice to dry this out
      def access
        if self.read_users.present?
          "limited"
        elsif self.read_groups.empty?
          "private"
        elsif self.read_groups.include? "public"
          "public"
        elsif self.read_groups.include? "registered"
          "restricted" 
        else 
          "limited"
        end
      end

      def access= access_level
        # Preserves group_exceptions when access_level changes to be not limited
        # This is a work-around for the limitation in Hydra: 1 group can't belong to both :read and :exceptions
        if self.access == "limited" && access_level != self.access
          self.group_exceptions = self.read_groups
          self.user_exceptions = self.read_users
          self.read_users = []
        end

        if access_level == "public"
          self.read_groups = ['public', 'registered'] 
        elsif access_level == "restricted"
          self.read_groups = ['registered'] 
        elsif access_level == "private"
          self.read_groups = []
        else #limited
          # Setting access to "limited" will copy group_exceptions to read_groups
          if self.access != "limited"
            self.read_groups = self.group_exceptions
            self.read_users = self.user_exceptions
          else
            self.read_groups = (self.read_groups + self.group_exceptions).uniq
            self.read_users = (self.read_users + self.user_exceptions).uniq
          end 
        end
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
    
      # user_exceptions and group_exceptions are used to store exceptions info
      # They aren't activated until access is set to limited
      def user_exceptions
        individuals.map {|k, v| k if v == 'exceptions'}.compact  
      end
    
      def user_exceptions= users
        set_entities(:exceptions, :person, users, user_exceptions)
      end
    
      # Return a list of groups that have exceptions permission
      def group_exceptions
        groups.map {|k, v| k if v == 'exceptions'}.compact
      end

      # Grant read permissions to the groups specified. Revokes read permission for all other groups.
      # @param[Array] groups a list of group names
      # @example
      #  r.read_groups= ['one', 'two', 'three']
      #  r.read_groups 
      #  => ['one', 'two', 'three']
      #
      def group_exceptions= groups
        set_entities(:exceptions, :group, groups, group_exceptions)
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
      # Overrides the one in hydra-access-controls/lib/hydra/model_mixins/rights_metadata.rb
      # to support group_exceptions
      def preserved(type, permission)
        # Always preserves exceptions
        g = Hash[quick_search_by_type(type).select {|k, v| v == 'exceptions'}] || {} 
    
        case permission
        when :exceptions
          # Preserves edit groups/users 
          g.merge! Hash[quick_search_by_type(type).select {|k, v| v == 'edit'}]
        when :read
          g.merge! Hash[quick_search_by_type(type).select {|k, v| v == 'edit'}] #Should this be read?!?
        when :discover
          g.merge! Hash[quick_search_by_type(type).select {|k, v| v == 'discover'}]
        end
        g
      end
    end
  end
end
