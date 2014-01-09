module Hydra
  module AccessControls
    module Visibility
      extend ActiveSupport::Concern

      def visibility=(value)
        return if value.nil?
        # only set explicit permissions
        case value
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          public_visibility!
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          registered_visibility!
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LIMITED
          limited_visibility!
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          private_visibility!
        else
          raise ArgumentError, "Invalid visibility: #{value.inspect}"
        end
      end

      def visibility
        if read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        elsif read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        elsif self.read_groups.any? || self.read_users.any?
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LIMITED
        else
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
      end

      private
      def public_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        self.read_users -= self.user_exceptions
        self.read_groups -= self.group_exceptions
        self.read_groups += [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end

      def registered_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        self.read_users -= self.user_exceptions
        self.read_groups -= self.group_exceptions
        self.read_groups -= [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        self.read_groups += [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      end

      def limited_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LIMITED
        self.read_users += self.user_exceptions
        self.read_groups += self.group_exceptions
        self.read_groups -= [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        self.read_groups -= [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      end

      def private_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        self.read_users -= self.user_exceptions
        self.read_groups -= self.group_exceptions
        self.read_groups -= [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        self.read_groups -= [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      end

    end
  end
end
