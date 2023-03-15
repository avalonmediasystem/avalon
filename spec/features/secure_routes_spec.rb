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

describe "Secure Routes" do
  after { Warden.test_reset! }
  let!(:admin) { FactoryBot.create(:administrator) }
  let!(:user)  { FactoryBot.create(:user) }

  describe "/about" do
    it "should provide access to admins" do
      login_as admin, scope: :user
      visit '/about'
      expect(page).to have_content('Environment')
    end

    xit "should not provide access to regular users" do
      login_as user, scope: :user
      visit '/about'
      expect(page).to have_content('Sample Content')
    end

    xit "should not provide access to anonymous users" do
      login_as user, scope: :user
      visit '/about'
      expect(page).to have_content('Sample Content')
    end
  end

  describe "/about/health" do
    it "should provide access to admins" do
      login_as admin, scope: :user
      visit '/about/health'
      expect(page).to have_content('Service Health')
    end

    xit "should not provide access to regular users" do
      login_as user, scope: :user
      visit '/about/health'
      expect(page).to have_content('Sample Content')
    end

    xit "should not provide access to anonymous users" do
      login_as user, scope: :user
      visit '/about/health'
      expect(page).to have_content('Sample Content')
    end
  end
end
