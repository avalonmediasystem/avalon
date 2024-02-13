# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe 'Playlist', skip: "Datatables fails to load only in test" do
  after { Warden.test_reset! }
  it 'checks navigation when create new playlist is accessed' do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/'
    click_link('Playlists')
    click_on('Create New Playlist')
    expect(page).to have_current_path('/playlists/new')
  end
  it 'is able to create private (default) playlist', js: true do
    hide_const('Avalon::GROUP_LDAP')
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'private_playlist')
    fill_in('playlist_comment', with: 'This is test')
    click_on('Create')
    visit '/playlists'
    expect(page).to have_content('private_playlist')
    expect(page).to have_content('Name')
    expect(page).to have_content('Visibility')
    expect(page).to have_content('Created')
    expect(page).to have_content('Size')
    expect(page).to have_content('Updated')
    expect(page).to have_content('Actions')
    expect(page).to have_content('Private')
    expect(page).to have_link('Edit')
    expect(page).to have_link('Delete')
  end
  it 'is able to view playlist by clicking on playlist name', js: true do
    hide_const('Avalon::GROUP_LDAP')
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'private_playlist')
    fill_in('playlist_comment', with: 'This is test')
    click_on('Create')
    visit '/playlists'
    click_on('private_playlist')
    expect(page).to have_content('private_playlist')
    expect(page).to have_link('Edit Playlist')
    expect(page).to have_content('This is test')
    expect(page).to have_content('This playlist currently has no playable items')
  end
  it 'is able to view playlist by accessing View Playlist', js: true do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'private_playlist')
    fill_in('playlist_comment', with: 'This is test')
    click_on('Create')
    visit '/playlists'
    click_on('Edit')
    click_on('View Playlist')
    expect(page).to have_content('private_playlist')
    expect(page).to have_link('Edit Playlist')
    expect(page).to have_content('This is test')
    expect(page).to have_content('This playlist currently has no playable items')
  end

  it 'deletes playlist permanently from playlists page', js: true do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'private_playlist')
    fill_in('playlist_comment', with: 'This is test')
    click_on('Create')
    visit '/playlists'
    click_link('Delete')
    click_link('Yes, Delete')
    visit '/playlists'
    expect(page).to have_content('Playlist was successfully destroyed')
    expect(page).to have_no_link('private_playlist')
  end

  it 'is able to delete playlist from edit playlist page', js: true do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'private_playlist')
    fill_in('playlist_comment', with: 'This is test')
    click_on('Create')
    visit '/playlists'
    click_on('Edit')
    click_on('Delete Playlist')
    click_on('Yes, Delete')
    visit '/playlists'
    expect(page).to have_content('Playlist was successfully destroyed')
    expect(page).to have_no_link('private_playlist')
  end

  it 'is able to create public playlist', js: true do
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'public_playlist')
    fill_in('playlist_comment', with: 'This is test')
    choose('Public')
    click_on('Create')
    visit '/playlists'
    expect(page).to have_content('Public')
  end
  it 'is able to edit playlist name and description', js: true, :retry => 3 do
    optional "Sometimes fails" if ENV['CI']
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'public_playlist')
    fill_in('playlist_comment', with: 'This is test')
    choose('Public')
    click_on('Create')
    visit '/playlists'
    click_on('Edit')
    expect(page).to have_content('Editing playlist')
    expect(page).to have_content('View Playlist')
    expect(page).to have_content('Delete Playlist')
    page.first("#playlist_edit_button").click
    expect(page).to have_button('Save Changes')
    fill_in('playlist_title', with: 'edit_public_playlist')
    fill_in('playlist_comment', with: 'Name and description edited')
    click_button('Save Changes')
    expect(page).to have_content('Playlist was successfully updated')
    expect(page).to have_content('edit_public_playlist')
    expect(page).to have_content('Name and description edited')
  end

  it 'is able to change public playlist to private', js: true, :retry => 3 do
    optional "Sometimes fails" if ENV['CI']
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'public_playlist')
    fill_in('playlist_comment', with: 'This is test')
    choose('Public')
    click_on('Create')
    visit '/playlists'
    click_on('Edit')
    expect(page).to have_content('Editing playlist')
    expect(page).to have_content('View Playlist')
    expect(page).to have_content('Delete Playlist')
    page.first("#playlist_edit_button").click
    expect(page).to have_button('Save Changes')
    choose('Private')
    click_button('Save Changes')
    expect(page).to have_content('Playlist was successfully updated')
    expect(page).to have_content('Private')
  end
  it 'is able to change private playlist to public', js: true, :retry => 3 do
    optional "Sometimes fails" if ENV['CI']
    user = FactoryBot.create(:administrator)
    login_as user, scope: :user
    visit '/playlists'
    click_on('Create New Playlist')
    fill_in('playlist_title', with: 'private_playlist')
    fill_in('playlist_comment', with: 'This is test')
    choose('Private')
    click_on('Create')
    visit '/playlists'
    click_on('Edit')
    expect(page).to have_content('Editing playlist')
    expect(page).to have_content('View Playlist')
    expect(page).to have_content('Delete Playlist')
    page.first("#playlist_edit_button").click
    expect(page).to have_button('Save Changes')
    choose('Public')
    click_button('Save Changes')
    expect(page).to have_content('Playlist was successfully updated')
    expect(page).to have_content('Public')
  end
end
