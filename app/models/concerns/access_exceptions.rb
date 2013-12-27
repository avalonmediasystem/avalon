module Avalon
  module AccessControls
    module AccessExceptions
      extend ActiveSupport::Concern

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
          self.read_users = self.user_exceptions
          self.read_groups = self.group_exceptions
        else
          self.read_users = []
          self.read_groups = []
          self.visibility = access_level
        end
      end

      def user_exceptions= users
        if access == 'limited'
          self.read_users = users
        end
        self.user_exceptions = users
      end

      def group_exceptions= groups
        if access == 'limited'
          self.read_groups = groups
        end
        self.group_exceptions = groups
      end

      def local_group_exceptions
        self.group_exceptions.select {|g| Admin::Group.exists? g}
      end

      def virtual_group_exceptions
        self.group_exceptions - local_group_exceptions
      end


      #Move hidden into separate concern?
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
        self.discover_groups.include? "nobody"
      end
    end
  end
end
