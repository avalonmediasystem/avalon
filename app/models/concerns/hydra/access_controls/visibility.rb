module Hydra
  module AccessControls
    module Visibility
      extend ActiveSupport::Concern

      def public_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        self.read_groups += [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end

      def registered_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        self.read_groups -= [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        self.read_groups += [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      end

      def private_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        self.read_groups -= [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        self.read_groups -= [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      end

    end
  end
end
