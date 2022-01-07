# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

describe 'Identity' do
  after { Warden.test_reset! }
  it 'returns error when a user is created twice' do
    test_username = 'Identity User'
    test_email = 'identity_user_1@example.com'
    test_password = 'identity'
    visit "/users/auth/identity/register"
    fill_in('name', with: test_username)
    fill_in('email', with: test_email)
    fill_in('password', with: test_password)
    fill_in('password_confirmation', with: test_password)
    click_on('Connect')
    expect(page.current_url).to eq('http://www.example.com/')
    visit 'users/sign_out'
    expect(page).to have_content('Signed out successfully.')
    visit "/users/auth/identity/register"
    fill_in('name', with: test_username)
    fill_in('email', with: test_email)
    fill_in('password', with: test_password)
    fill_in('password_confirmation', with: test_password)
    click_on('Connect')
    expect(page).to have_content('Email is taken.')
  end
end
