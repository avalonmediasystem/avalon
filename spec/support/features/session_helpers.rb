# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

# frozen_string_literal: true
# Copied from Hyrax: spec/support/features/session_helpers.rb
module Features
  module SessionHelpers
    def sign_in(who = :user)
      user = who.is_a?(User) ? who : FactoryBot.build(:user).tap(&:save!)
      visit '/users/sign_in'
      within('div.omniauth-form form') do
        fill_in 'Username or email', with: user.email
        fill_in 'Password', with: user.password
        click_on 'Connect'
      end
    end
  end
end
