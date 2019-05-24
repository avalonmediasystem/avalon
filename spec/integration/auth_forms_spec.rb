# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

describe AuthFormsController, type: :feature do
  scenario "User reaches the login screen" do
    visit "/users/auth/identity"
    expect(page).to have_text('Avalon Media System')
  end
  
  scenario "User reaches the registration screen" do
    visit "/users/auth/identity/register"
    expect(page).to have_text('Avalon Media System')
  end
end
