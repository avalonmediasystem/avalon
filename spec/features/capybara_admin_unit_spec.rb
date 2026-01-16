# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

describe 'Admin Unit' do
  before do
    @user = FactoryBot.create(:administrator)
  end
  after { Warden.test_reset! }
  it 'checks navigation when create new unit is accessed' do
    login_as @user, scope: :user
    visit '/'
    click_link('Manage Content')
    expect(page).to have_current_path('/admin/dashboard')
    expect(page).to have_link('Create Unit')
    click_link('Create Unit')
    expect(page).to have_current_path('/admin/units/new')
    expect(page).to have_content('Name')
    expect(page).to have_content('Description')
    expect(page).to have_link('Cancel')
  end
  it 'is able to create a new unit' do
    login_as @user, scope: :user
    visit '/admin/units/'
    click_link('Create Unit')
    fill_in('admin_unit_name', with: 'Test Unit')
    click_on('Create Unit')
    visit '/admin/units'
    expect(page).to have_content('Test Unit')
    expect(page).to have_content('Title')
    expect(page).to have_content('Items')
    expect(page).to have_content('Unit Administrators')
    expect(page).to have_content('Description')
    expect(page).to have_link('Delete')
  end
  it 'is able to view unit by clicking on unit name' do
    login_as @user, scope: :user
    visit '/admin/units'
    click_link('Create Unit')
    fill_in('admin_unit_name', with: 'Test Unit')
    click_on('Create Unit')
    visit '/admin/units'
    click_on('Test Unit')
    expect(page).to have_content('Test Unit')
    expect(page).to have_link('Create A Collection')
    expect(page).to have_link('List All Collections')
    expect(page).to have_button('Edit Unit Info')
  end
  it 'is able to delete a unit' do
    login_as @user, scope: :user
    visit '/admin/units'
    click_link('Create Unit')
    fill_in('admin_unit_name', with: 'Test Unit')
    click_on('Create Unit')
    visit '/admin/units'
    click_link('Delete')
    expect(page).to have_content('Are you certain you want to remove the unit Test Unit?')
    expect(page).to have_button('Yes, I am sure')
    expect(page).to have_link('No, go back')
  end
end
