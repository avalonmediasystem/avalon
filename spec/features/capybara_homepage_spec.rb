# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

describe 'homepage' do
  after { Warden.test_reset! }
  it 'validates presence of header and footer on homepage' do
    visit 'http://0.0.0.0:3000'
    page.assert_text('Sample Content')
    page.has_link?('Browse')
    page.assert_text('Featured Collection')
    page.assert_text('Featured Video')
    page.assert_text('Featured Audio')
    page.has_link?('Avalon Media System Project Website')
    page.has_link?('Contact Us')
    page.assert_text('Avalon Media System Release')
    page.assert_text('Search')
  end
  it 'validates absence of features when not logged in' do
    visit '/'
    page.has_no_link?('Manage Content')
    page.has_no_link?('Manage Groups')
    page.has_no_link?('Manage Selected Items')
    page.has_no_link?('Playlists')
    page.has_no_link?('Sign out>>')
  end
  # This test will work only when there are videos already present in avalon
  it 'checks vertical navigation options on homepage' do
    user = FactoryGirl.create(:user)
    login_as user, scope: :user
    visit '/'
    page.has_link?('Main contributor')
    page.has_link?('Date')
    page.has_link?('Collection')
    page.has_link?('Unit')
    page.has_link?('Language')
  end
end
describe 'checks navigation to external links' do
  it 'checks navigation to Avalon Website' do
    visit '/'
    click_link('Avalon Media System Project Website')
    expect(page.status_code).to eq(200)
    expect(page.current_url).to eq('http://www.avalonmediasystem.org/')
  end
  it 'checks navigation to Contact us page' do
    visit '/'
    click_link('Contact Us')
    expect(page.current_url).to eq('http://www.example.com/comments')
    page.assert_text('Contact us')
    page.assert_text('Name')
    page.assert_text('Email address')
    page.assert_text('Confirm email address')
    page.assert_text('Subject')
    page.assert_text('Comment')
    page.has_button?('Submit comments')
  end
  it 'verifies presence of features after login' do
    user = FactoryGirl.create(:administrator)
    login_as user, scope: :user
    visit'/'
    page.has_link?('Manage Content')
    page.has_link?('Manage Groups')
    page.has_link?('Manage Selected Items')
    page.has_link?('Playlists')
    page.has_link?('Sign out')
    page.assert_text(user.username)
  end
end

describe 'Sign in page' do
  it 'validates presence of items on login page' do
    visit 'http://localhost:3000/users/auth/identity'
    #page.assert_text('Identity Verification')
    page.assert_text('Login:')
    page.assert_text('Password:')
    page.has_link?('Create an Identity')
    page.has_button?('Connect')
    click_button 'Connect'
    # page.assert_text('Successfully logged into the system')
  end
  it 'validates presence of items on register page' do
    visit 'http://localhost:3000/users/auth/identity/register'
    page.assert_text('Email:')
    page.assert_text('Password:')
    page.assert_text('Confirm Password:')
  end
  it 'is able to create new account' do
    hide_const('Avalon::GROUP_LDAP')
    visit '/users/auth/identity/register'
    fill_in 'email', with: 'user1@example.com'
    fill_in 'password', with: 'test123'
    # binding.pry
    fill_in 'password_confirmation', with: 'test123'
    # save_and_open_page
    click_on 'Connect'
  end
end
