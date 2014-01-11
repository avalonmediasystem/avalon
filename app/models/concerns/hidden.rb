module Avalon
  module AccessControls
    module Hidden
      extend ActiveSupport::Concern

      #Move hidden into separate concern?
      def hidden= value
        groups = self.discover_groups
        if value
          groups += ["nobody"]
        else
          groups -= ["nobody"]
        end
        self.discover_groups = groups.uniq
      end

      def hidden?
        self.discover_groups.include? "nobody"
      end
    end
  end
end
