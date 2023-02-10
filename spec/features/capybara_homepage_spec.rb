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

describe 'homepage' do
  after { Warden.test_reset! }
  xit 'validates presence of header and footer on homepage' do
    visit '/'
    expect(page).to have_content('Sample Content')
    expect(page).to have_link('Browse')
    expect(page).to have_content('Featured Collection')
    expect(page).to have_content('Featured Video')
    expect(page).to have_content('Featured Audio')
    expect(page).to have_link('Avalon Media System Project Website')
    expect(page).to have_link('Contact Us')
    expect(page).to have_content('Avalon Media System Release')
    expect(page).to have_content('Search')
  end
  it 'validates absence of features when not logged in' do
    visit '/'
    expect(page).to have_no_link('Manage Content')
    expect(page).to have_no_link('Manage Groups')
    expect(page).to have_no_link('Selected Items')
    expect(page).to have_no_link('Playlists')
    expect(page).to have_no_link('Sign out>>')
  end
  # This test will work only when there are videos already present in avalon
  xit 'checks vertical navigation options on homepage' do
    visit '/'
    expect(page).to have_link('Main contributor')
    expect(page).to have_link('Date')
    expect(page).to have_link('Collection')
    expect(page).to have_link('Unit')
    expect(page).to have_link('Language')
  end
end
describe 'checks navigation to external links' do
  it 'checks navigation to Avalon Website' do
    visit '/'
    expect(page).to have_link('Avalon Media System Project Website', href: "http://www.avalonmediasystem.org")
  end
  it 'checks navigation to Contact us page' do
    visit '/'
    click_link('Contact Us')
    expect(page.current_path).to eq('/comments')
    expect(page).to have_content('Contact us')
    expect(page).to have_content('Name')
    expect(page).to have_content('Email address')
    expect(page).to have_content('Confirm email address')
    expect(page).to have_content('Subject')
    expect(page).to have_content('Comment')
    expect(page).to have_button('Submit comments')
  end
  it 'verifies presence of features after login' do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit'/'
    expect(page).to have_link('Manage Content')
    expect(page).to have_link('Manage Groups')
    expect(page).to have_link('Selected Items')
    expect(page).to have_link('Playlists')
    expect(page).to have_link('Sign out')
    expect(page).to have_content(user.user_key)
  end
end

describe 'Sign in page' do
  it 'validates presence of items on login page' do
    visit '/users/sign_in'
    expect(page).to have_content('Username or email')
    expect(page).to have_content('Password')
    expect(page).to have_link('Sign up')
    expect(page).to have_button('Connect')
  end
  it 'validates presence of items on register page' do
    visit '/users/sign_up'
    expect(page).to have_content('Username')
    expect(page).to have_content('Email')
    expect(page).to have_content('Password')
    expect(page).to have_content('Password confirmation')
  end
  it 'is able to create new account' do
    hide_const('Avalon::GROUP_LDAP')
    visit '/users/sign_up'
    fill_in 'Username', with: 'user1@example.com'
    fill_in 'Email', with: 'user1@example.com'
    fill_in 'Password', with: 'test123'
    fill_in 'Password confirmation', with: 'test123'
    click_on 'Sign up'
  end
end
