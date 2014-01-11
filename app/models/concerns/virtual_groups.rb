module Avalon
  module AccessControls
    module VirtualGroups
      extend ActiveSupport::Concern

      def local_read_groups
        self.read_groups.select {|g| Admin::Group.exists? g}
      end

      def virtual_read_groups
        self.read_groups - ["public", "registered"] - local_read_groups
      end
    end
  end
end
