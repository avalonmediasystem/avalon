# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---


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
