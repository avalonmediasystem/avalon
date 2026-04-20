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
  it 'is able to create a new unit' do
    login_as @user, scope: :user
    visit new_admin_unit_path
    fill_in('admin_unit_name', with: 'Test Unit')
    click_on('Create Unit')
    expect(page).to have_content('Unit was successfully created.')
    expect(page.current_path).to match /\/admin\/units\/.+/
    expect(page).to have_content('Test Unit')
  end
  it 'is able to view unit by clicking on unit name' do
    @unit = FactoryBot.create(:unit, name: 'Test Unit')
    login_as @user, scope: :user
    visit admin_unit_path(@unit)
    expect(page).to have_content('Test Unit')
    expect(page).to have_link('Create A Collection')
    expect(page).to have_link('List All Collections')
    expect(page).to have_button('Edit Unit Info')
  end
  it 'is able to delete a unit' do
    @unit = FactoryBot.create(:unit, name: 'Test Unit')
    login_as @user, scope: :user
    visit remove_admin_unit_path(@unit)
    expect(page).to have_content('Are you certain you want to remove the unit Test Unit?')
    expect(page).to have_button('Yes, I am sure')
    expect(page).to have_link('No, go back')
  end
end
