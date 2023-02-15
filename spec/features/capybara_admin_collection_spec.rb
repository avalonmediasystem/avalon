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

describe 'Admin Collection' do
  after { Warden.test_reset! }
  it 'checks navigation when create new collection is accessed' do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/'
    click_link('Manage Content')
    expect(page).to have_current_path('/admin/collections')
    expect(page).to have_link('Create Collection')
    click_link('Create Collection')
    expect(page).to have_current_path('/admin/collections/new')
    expect(page).to have_content('Name')
    expect(page).to have_content('Description')
    expect(page).to have_content('Unit')
    expect(page).to have_content('Default Unit')
    expect(page).to have_link('Cancel')
  end
  it 'is able to create a new collection' do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/admin/collections/'
    click_link('Create Collection')
    fill_in('admin_collection_name', with: 'Test Collection')
    select('Default Unit', from: 'admin_collection_unit')
    click_on('Create Collection')
    visit '/admin/collections'
    expect(page).to have_content('Test Collection')
    expect(page).to have_content('Title')
    expect(page).to have_content('Items')
    expect(page).to have_content('Managers')
    expect(page).to have_content('Description')
    expect(page).to have_link('Delete')
  end
  it 'is able to view collection by clicking on collection name' do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/admin/collections'
    click_link('Create Collection')
    fill_in('admin_collection_name', with: 'Test Collection')
    select('Default Unit', from: 'admin_collection_unit')
    click_on('Create Collection')
    visit '/admin/collections'
    click_on('Test Collection')
    expect(page).to have_content('Test Collection')
    expect(page).to have_link('Create An Item')
    expect(page).to have_link('List All Items')
    expect(page).to have_button('Edit Collection Info')
    expect(page).to have_content('Default Unit')
  end
  it 'is able to delete a collection' do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/admin/collections'
    click_link('Create Collection')
    fill_in('admin_collection_name', with: 'Test Collection')
    select('Default Unit', from: 'admin_collection_unit')
    click_on('Create Collection')
    visit '/admin/collections'
    click_link('Delete')
    expect(page).to have_content('Are you certain you want to remove the collection Test Collection?')
    expect(page).to have_button('Yes, I am sure')
    expect(page).to have_link('No, go back')
  end
end
