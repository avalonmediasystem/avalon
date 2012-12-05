module Hydrant
  module Controller
    module ControllerBehavior

      def set_default_item_permissions item
        unless item.rightsMetadata.nil?
          item.edit_groups = ["archivist"]
          item.apply_depositor_metadata user_key
        end
      end

    end
  end
end
