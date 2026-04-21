# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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
  before do
    @user = FactoryBot.create(:administrator)
    @unit = FactoryBot.create(:unit)
  end
  after { Warden.test_reset! }
  it 'checks navigation when create new collection is accessed from unit page' do
    login_as @user, scope: :user
    visit admin_unit_path(@unit)
    expect(page).to have_link('Create A Collection')
    click_link('Create A Collection')
    expect(page).to have_current_path("/admin/collections/new?unit_id=#{@unit.id}")
    expect(page).to have_content('Name')
    expect(page).to have_content('Description')
    expect(page).to have_content('Unit')
    expect(page).to have_content(@unit.name)
    expect(page).to have_link('Cancel')
  end
  it 'is able to create a new collection' do
    login_as @user, scope: :user
    visit new_admin_collection_path
    fill_in('admin_collection_name', with: 'Test Collection')
    select(@unit.name, from: 'admin_collection[unit_id]')
    click_on('Create Collection')
    expect(page).to have_content('Collection was successfully created.')
    expect(page.current_path).to match /\/admin\/collections\/.+/
    expect(page).to have_content('Test Collection')
  end
  it 'is able to view collection by clicking on collection name' do
    @collection = FactoryBot.create(:collection, unit: @unit, name: 'Test Collection')
    login_as @user, scope: :user
    visit admin_collection_path(@collection)
    expect(page).to have_content('Test Collection')
    expect(page).to have_link('Create An Item')
    expect(page).to have_link('List All Items')
    expect(page).to have_button('Edit Collection Info')
    expect(page).to have_content(@unit.name)
  end
  it 'is able to delete a collection' do
    @collection = FactoryBot.create(:collection, unit: @unit, name: 'Test Collection')
    login_as @user, scope: :user
    visit remove_admin_collection_path(@collection)
    expect(page).to have_content('Are you certain you want to remove the collection Test Collection?')
    expect(page).to have_button('Yes, I am sure')
    expect(page).to have_link('No, go back')
  end
end
