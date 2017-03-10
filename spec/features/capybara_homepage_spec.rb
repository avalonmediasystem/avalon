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
    page.should have_content('Sample Content')
    page.should have_link('Browse')
    page.should have_content('Featured Collection')
    page.should have_content('Featured Video')
    page.should have_content('Featured Audio')
    page.should have_link('Avalon Media System Project Website')
    page.should have_link('Contact Us')
    page.should have_content('Avalon Media System Release 6.0')
    page.should have_content('Search')
  end
  it 'validates absence of features when not logged in' do
    visit '/'
    page.should have_no_link('Manage Content')
    page.should have_no_link('Manage Groups')
    page.should have_no_link('Manage Selected Items')
    page.should have_no_link('Playlists')
    page.should have_no_link('Sign out>>')
  end
  # This test will work only when there are videos already present in avalon
  xit 'checks vertical navigation options on homepage' do
    visit ''
    page.should have_link('Main contributor')
    page.should have_link('Date')
    page.should have_link('Collection')
    page.should have_link('Unit')
    page.should have_link('Language')
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
    page.should have_content('Contact us')
    page.should have_content('Name')
    page.should have_content('Email address')
    page.should have_content('Confirm email address')
    page.should have_content('Subject')
    page.should have_content('Comment')
    page.should have_button('Submit comments')
  end
  it 'verifies presence of features after login' do
    user = FactoryGirl.create(:administrator)
    login_as user, scope: :user
    visit'/'
    page.should have_link('Manage Content')
    page.should have_link('Manage Groups')
    page.should have_link('Manage Selected Items')
    page.should have_link('Playlists')
    page.should have_link('Sign out')
    page.should have_content(user.username)
  end
end

describe 'Sign in page' do
  it 'validates presence of items on login page' do
    visit 'http://localhost:3000/users/auth/identity'
    #page.should have_content('Identity Verification')
    page.should have_content('Login:')
    page.should have_content('Password:')
    page.should have_link('Create an Identity')
    page.should have_button('Connect')
    click_button 'Connect'
    # page.should have_content('Successfully logged into the system')
  end
  it 'validates presence of items on register page' do
    visit 'http://localhost:3000/users/auth/identity/register'
    page.should have_content('Email:')
    page.should have_content('Password:')
    page.should have_content('Confirm Password:')
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
