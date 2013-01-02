module Hydrant
  module Controller
    module ControllerBehavior
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def set_default_item_permissions( item, user_key )
          unless item.rightsMetadata.nil?
            item.edit_groups = ["archivist"]
            item.apply_depositor_metadata user_key
          end
        end
      end

    end
  end
end
