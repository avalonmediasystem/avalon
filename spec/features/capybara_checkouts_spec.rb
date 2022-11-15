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

describe "Checkouts", skip: "Datatables fails to load only in test" do
  after { Warden.test_reset! }
  before :each do
    @user = FactoryBot.create(:user)
    login_as @user, scope: :user
  end
  let(:active_checkout) { FactoryBot.create(:checkout, user: @user) }
  let(:returned_checkout) { FactoryBot.create(:checkout, user: @user, return_time: DateTime.current - 1.day) }

  it "displays a table of active checkouts" do
    visit('/checkouts')
    expect(page).to have_content('Media object')
    expect(page).to have_content('Checkout time')
    expect(page).to have_content('Return time')
    expect(page).to have_content('Time remaining')
    expect(page).to have_link('Return All')
    expect(page).to have_link('Return')
    expect(page).to have_link(active_checkout.media_object.title)
    expect(page).not_to have_link(returned_checkout.media_object.title)
  end

  it "displays active and inactive checkouts when checkbox is checked", js: true do
    visit('/checkouts')
    check('inactive_checkouts')
    expect(page).to have_link(active_checkout.media_object.title)
    expect(page).to have_link(returned_checkout.media_object.title)
  end
end
