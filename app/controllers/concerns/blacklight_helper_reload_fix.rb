module BlacklightHelperReloadFix
  extend ActiveSupport::Concern

  included do
    if Rails.env.development?
      # Hot-reload of rails confuses which Blacklight helpers it wants to use,
      # we beat it into submission so that it uses ours ...
      include ActionView::Helpers::TagHelper
      include ActionView::Context
      include ActionView::Helpers::NumberHelper
      include ActionView::Helpers::TextHelper
      include Blacklight::FacetsHelperBehavior
      include Blacklight::ConfigurationHelperBehavior
      include Blacklight::LocalBlacklightHelper

      Blacklight::LocalBlacklightHelper.instance_methods.each do |method|
        helper_method method
      end
    end
  end
end
