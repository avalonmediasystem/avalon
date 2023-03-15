# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

require 'rails_helper'

describe "modules/_google_analytics.html.erb", type: :view do
  context "Google Analytics is configured" do
    before do
      Settings.google_analytics_tracking_id = "arandomid"
    end

    it 'includes GA code' do
      render
      expect(rendered).to have_selector(:css, "script[src='https://www.googletagmanager.com/gtag/js?id=arandomid']", visible: false)
    end
  end

  context "Google Analytics is not configured" do
    before do
      Settings.google_analytics_tracking_id = nil
    end

    it 'does not include GA code' do
      render
      expect(rendered).to have_none_of_selectors(:css, "script[src='https://www.googletagmanager.com/gtag/js?id=arandomid']", visible: false)
    end
  end
end
