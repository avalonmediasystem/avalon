module Hydra
  module Datastream
    class NonIndexedRightsMetadata < Hydra::Datastream::RightsMetadata    
  
      @terminology = Hydra::Datastream::RightsMetadata.terminology

      def to_solr(solr_doc=Hash.new)
        return solr_doc
      end

      # Default access for new items 
      # Copied from MediaObject, would be nice to dry this out
      def access
        logger.debug "<< ACCESS >>"
        logger.debug "<< #{self.read_groups} >>"
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
        logger.debug "<< HIDDEN VALUE #{value}"
        groups = self.discover_groups
        if value
          groups << "nobody"
        else
          groups.delete "nobody"
        end
        logger.debug "<< DISCOVER GROUPS #{groups.inspect}"
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
    
      # Return a list of groups that have discover permission
      def discover_groups
        groups.map {|k, v| k if v == 'discover'}.compact
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for all other groups.
      # @param[Array] groups a list of group names
      # @example
      #  r.discover_groups= ['one', 'two', 'three']
      #  r.discover_groups 
      #  => ['one', 'two', 'three']
      #
      def discover_groups=(groups)
        set_discover_groups(groups, discover_groups)
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.discover_groups_string= 'one, two, three'
      #  r.discover_groups 
      #  => ['one', 'two', 'three']
      #
      def discover_groups_string=(groups)
        self.discover_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def discover_groups_string
        self.discover_groups.join(', ')
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for
      # any of the eligible_groups that are not in groups.
      # This may be used when different users are responsible for setting different
      # groups.  Supply the groups the current user is responsible for as the 
      # 'eligible_groups'
      # @param[Array] groups a list of groups
      # @param[Array] eligible_groups the groups that are eligible to have their discover permssion revoked. 
      # @example
      #  r.discover_groups = ['one', 'two', 'three']
      #  r.discover_groups 
      #  => ['one', 'two', 'three']
      #  r.set_discover_groups(['one'], ['three'])
      #  r.discover_groups
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_discover_groups(groups, eligible_groups)
        set_entities(:discover, :group, groups, eligible_groups)
      end

      def discover_users
        individuals.map {|k, v| k if v == 'discover'}.compact
      end

      # Grant discover permissions to the users specified. Revokes discover permission for all other users.
      # @param[Array] users a list of usernames
      # @example
      #  r.discover_users= ['one', 'two', 'three']
      #  r.discover_users 
      #  => ['one', 'two', 'three']
      #
      def discover_users=(users)
        set_discover_users(users, discover_users)
      end

      # Grant discover permissions to the groups specified. Revokes discover permission for all other users.
      # @param[String] users a list of usernames
      # @example
      #  r.discover_users_string= 'one, two, three'
      #  r.discover_users 
      #  => ['one', 'two', 'three']
      #
      def discover_users_string=(users)
        self.discover_users=users.split(/[\s,]+/)
      end

      # Display the users as a comma delimeted string
      def discover_users_string
        self.discover_users.join(', ')
      end

      # Grant discover permissions to the users specified. Revokes discover permission for
      # any of the eligible_users that are not in users.
      # This may be used when different users are responsible for setting different
      # users.  Supply the users the current user is responsible for as the 
      # 'eligible_users'
      # @param[Array] users a list of users
      # @param[Array] eligible_users the users that are eligible to have their discover permssion revoked. 
      # @example
      #  r.discover_users = ['one', 'two', 'three']
      #  r.discover_users 
      #  => ['one', 'two', 'three']
      #  r.set_discover_users(['one'], ['three'])
      #  r.discover_users
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_discover_users(users, eligible_users)
        set_entities(:discover, :person, users, eligible_users)
      end

      # Return a list of groups that have discover permission
      def read_groups
        groups.map {|k, v| k if v == 'read'}.compact
      end

      # Grant read permissions to the groups specified. Revokes read permission for all other groups.
      # @param[Array] groups a list of group names
      # @example
      #  r.read_groups= ['one', 'two', 'three']
      #  r.read_groups 
      #  => ['one', 'two', 'three']
      #
      def read_groups=(groups)
        set_read_groups(groups, read_groups)
      end

      # Grant read permissions to the groups specified. Revokes read permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.read_groups_string= 'one, two, three'
      #  r.read_groups 
      #  => ['one', 'two', 'three']
      #
      def read_groups_string=(groups)
        self.read_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def read_groups_string
        self.read_groups.join(', ')
      end

      # Grant read permissions to the groups specified. Revokes read permission for
      # any of the eligible_groups that are not in groups.
      # This may be used when different users are responsible for setting different
      # groups.  Supply the groups the current user is responsible for as the 
      # 'eligible_groups'
      # @param[Array] groups a list of groups
      # @param[Array] eligible_groups the groups that are eligible to have their read permssion revoked. 
      # @example
      #  r.read_groups = ['one', 'two', 'three']
      #  r.read_groups 
      #  => ['one', 'two', 'three']
      #  r.set_read_groups(['one'], ['three'])
      #  r.read_groups
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_read_groups(groups, eligible_groups)
        set_entities(:read, :group, groups, eligible_groups)
      end

      def read_users
        individuals.map {|k, v| k if v == 'read'}.compact
      end

      # Grant read permissions to the users specified. Revokes read permission for all other users.
      # @param[Array] users a list of usernames
      # @example
      #  r.read_users= ['one', 'two', 'three']
      #  r.read_users 
      #  => ['one', 'two', 'three']
      #
      def read_users=(users)
        set_read_users(users, read_users)
      end

      # Grant read permissions to the groups specified. Revokes read permission for all other users.
      # @param[String] users a list of usernames
      # @example
      #  r.read_users_string= 'one, two, three'
      #  r.read_users 
      #  => ['one', 'two', 'three']
      #
      def read_users_string=(users)
        self.read_users=users.split(/[\s,]+/)
      end

      # Display the users as a comma delimeted string
      def read_users_string
        self.read_users.join(', ')
      end

      # Grant read permissions to the users specified. Revokes read permission for
      # any of the eligible_users that are not in users.
      # This may be used when different users are responsible for setting different
      # users.  Supply the users the current user is responsible for as the 
      # 'eligible_users'
      # @param[Array] users a list of users
      # @param[Array] eligible_users the users that are eligible to have their read permssion revoked. 
      # @example
      #  r.read_users = ['one', 'two', 'three']
      #  r.read_users 
      #  => ['one', 'two', 'three']
      #  r.set_read_users(['one'], ['three'])
      #  r.read_users
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_read_users(users, eligible_users)
        set_entities(:read, :person, users, eligible_users)
      end


      # Return a list of groups that have edit permission
      def edit_groups
        groups.map {|k, v| k if v == 'edit'}.compact
      end

      # Grant edit permissions to the groups specified. Revokes edit permission for all other groups.
      # @param[Array] groups a list of group names
      # @example
      #  r.edit_groups= ['one', 'two', 'three']
      #  r.edit_groups 
      #  => ['one', 'two', 'three']
      #
      def edit_groups=(groups)
        set_edit_groups(groups, edit_groups)
      end

      # Grant edit permissions to the groups specified. Revokes edit permission for all other groups.
      # @param[String] groups a list of group names
      # @example
      #  r.edit_groups_string= 'one, two, three'
      #  r.edit_groups 
      #  => ['one', 'two', 'three']
      #
      def edit_groups_string=(groups)
        self.edit_groups=groups.split(/[\s,]+/)
      end

      # Display the groups a comma delimeted string
      def edit_groups_string
        self.edit_groups.join(', ')
      end

      # Grant edit permissions to the groups specified. Revokes edit permission for
      # any of the eligible_groups that are not in groups.
      # This may be used when different users are responsible for setting different
      # groups.  Supply the groups the current user is responsible for as the 
      # 'eligible_groups'
      # @param[Array] groups a list of groups
      # @param[Array] eligible_groups the groups that are eligible to have their edit permssion revoked. 
      # @example
      #  r.edit_groups = ['one', 'two', 'three']
      #  r.edit_groups 
      #  => ['one', 'two', 'three']
      #  r.set_edit_groups(['one'], ['three'])
      #  r.edit_groups
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_edit_groups(groups, eligible_groups)
        set_entities(:edit, :group, groups, eligible_groups)
      end

      def edit_users
        individuals.map {|k, v| k if v == 'edit'}.compact
      end

      # Grant edit permissions to the groups specified. Revokes edit permission for all other groups.
      # @param[Array] users a list of usernames
      # @example
      #  r.edit_users= ['one', 'two', 'three']
      #  r.edit_users 
      #  => ['one', 'two', 'three']
      #
      def edit_users=(users)
        set_edit_users(users, edit_users)
      end

      # Grant edit permissions to the users specified. Revokes edit permission for
      # any of the eligible_users that are not in users.
      # This may be used when different users are responsible for setting different
      # users.  Supply the users the current user is responsible for as the 
      # 'eligible_users'
      # @param[Array] users a list of users
      # @param[Array] eligible_users the users that are eligible to have their edit permssion revoked. 
      # @example
      #  r.edit_users = ['one', 'two', 'three']
      #  r.edit_users 
      #  => ['one', 'two', 'three']
      #  r.set_edit_users(['one'], ['three'])
      #  r.edit_users
      #  => ['one', 'two']  ## 'two' was not eligible to be removed
      #
      def set_edit_users(users, eligible_users)
        set_entities(:edit, :person, users, eligible_users)
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
          g.merge! Hash[quick_search_by_type(type).select {|k, v| v == 'edit'}]
        when :discover
          g.merge! Hash[quick_search_by_type(type).select {|k, v| v == 'discover'}]
        end
        g
      end

    end
  end
end
