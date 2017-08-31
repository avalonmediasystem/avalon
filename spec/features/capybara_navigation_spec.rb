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

describe 'checks navigation after logging in' do
  after { Warden.test_reset! }
  it 'checks navigation to Browse' do
    user = FactoryGirl.create(:administrator)
    login_as user, scope: :user
    visit '/'
    click_link('Browse')
    expect(page.current_url).to eq('http://www.example.com/catalog?q=&search_field=all_fields&utf8=%E2%9C%93')
  end
  it 'checks navigation to Manage Content' do
    user = FactoryGirl.create(:administrator)
    login_as user, scope: :user
    visit '/'
    click_link('Manage Content')
    expect(page.current_url).to eq('http://www.example.com/admin/collections')
    page.assert_text('Skip to main content')
    page.has_link?('Manage Selected Items (0)')
    page.has_button?('Create Collection')
    page.assert_text('Name')
    page.assert_text('Description')
    page.assert_text('Unit')
    page.assert_text('Default Unit')
    page.has_link?('Cancel')
  end
  it 'checks naviagtion to Manage Groups' do
    user = FactoryGirl.create(:administrator)
    login_as user, scope: :user
    visit '/'
    click_link('Manage Groups')
    expect(page.current_url).to eq('http://www.example.com/admin/groups')
    page.assert_text('System Groups')
    page.assert_text('Additional Groups')
    page.assert_text('Group Name')
    page.assert_text('group_manager')
    page.assert_text('administrator')
    page.assert_text('manager')
  end
  it 'checks naviagtion to Playlist' do
    user = FactoryGirl.create(:administrator)
    login_as user, scope: :user
    visit '/'
    click_link('Playlist')
    expect(page.current_url).to eq('http://www.example.com/playlists')
    page.assert_text('Playlists')
    page.assert_text('Create New Playlist')
  end
  it 'is able to sign out' do
    user = FactoryGirl.create(:administrator)
    login_as user, scope: :user
    visit '/'
    click_link('Sign out', match: :first)
    page.assert_text('Signed out successfully')
  end
end

describe 'Search' do
  it 'is able to enter keyword and perform search' do
    visit '/'
    fill_in('Search', with: 'Video')
    click_button 'Search'
    expect(page.current_url).to eq('http://www.example.com/catalog?utf8=%E2%9C%93&search_field=all_fields&q=Video')
  end
  it 'gives appropriate error when keyword returns no results' do
    visit '/'
    fill_in('Search', with: 'Video')
    click_button 'Search'
    page.assert_text('No results found for your search')
    page.assert_text('No entries found')
    page.assert_text('Use fewer keywords to start, then refine your search using the links on the left')
    page.assert_text('Try modifying your search')
  end
end
