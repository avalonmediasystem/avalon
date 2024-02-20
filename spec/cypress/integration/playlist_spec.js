/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 * 
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software distributed
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
*/

context('Playlists', () => {

	// checks navigation when create new playlist is accessed
	it('.create_playlists()', () => {
		cy.login('administrator')
		cy.visit('/playlists/new')
	})

	// is able to create private (default) playlist
	it('.validate_create_playlist()', () => {
		cy.login('administrator')
		cy.visit('/playlists/new')
		cy.get('#playlist_title').type('Cypress Testing')
		cy.get('#playlist_comment').type('Cypress testing comments')
		cy.get('#submit-playlist-form').click()
		cy.visit('/playlists')
		cy.contains('Cypress Testing')
		cy.contains('Visibility')
		cy.contains('Created')
		cy.contains('Updated')
		cy.contains('Actions')
		cy.contains('Private')
		cy.contains('Size')
		cy.contains('Delete')
		cy.contains('Edit')
		cy.contains('Delete')
	})

	// is able to view playlist by clicking on playlist name
	it('.view_playlist()', () => {
		cy.login('administrator')
		cy.visit('/playlists/new')

		cy.get('#playlist_title').type('Cypress Testing2')
		cy.get('#playlist_comment').type('Cypress testing2 comments')
		cy.get('#submit-playlist-form').click()

		cy.visit('/playlists')
		cy.contains('Cypress Testing2').click()
		cy.contains('Edit Playlist')
		cy.contains('Cypress testing2 comments')
		cy.contains('This playlist currently has no playable items')
	})

	// deletes playlist permanently from playlists page
	it('.delete_playlist()', () => {
		cy.login('administrator')
		cy.visit('/playlists/new')

		cy.get('#playlist_title').type('Cypress Testing3')
		cy.get('#playlist_comment').type('Cypress testing3 comments')
		cy.get('#submit-playlist-form').click()

		cy.visit('/playlists')
		cy.contains('Delete').click()
		cy.contains('Yes, Delete').click()

		cy.visit('/playlists')
		cy.contains('Cypress Testing3').should('not.exist')
	})

	// is able to delete playlist from edit playlist page
	it('.delete_playlist_edit_page()', () => {
		cy.login('administrator')
		cy.visit('/playlists/new')

		cy.get('#playlist_title').type('Cypress Testing4')
		cy.get('#playlist_comment').type('Cypress testing4 comments')
		cy.get('#submit-playlist-form').click()

		cy.visit('/playlists')
		cy.contains('Cypress Testing4').click()
		cy.contains('Edit Playlist').click()

		cy.contains('Delete Playlist').click()
		cy.contains('Yes, Delete').click()
		cy.contains('Playlist was successfully destroyed.')
		cy.visit('/playlists')
		cy.contains('Cypress Testing4').should('not.exist')
	})

	// is able to create public playlist
	it('.create_public_playlist()', () => {
		cy.login('administrator')
		cy.visit('/playlists/new')

		cy.get('#playlist_title').type('Cypress Testing5')
		cy.get('#playlist_comment').type('Cypress testing5 comments')
		cy.contains('Public').click()
		cy.get('#submit-playlist-form').click()

		cy.visit('/playlists')
		cy.contains('Cypress Testing5')
		cy.contains('Public')
	})

	// is able to edit playlist name and description
	it('.edit_playlist_name()', () => {
		cy.login('administrator')
		cy.visit('/playlists')

		cy.contains('Cypress Testing5').click()
		cy.contains('Edit Playlist').click()

		cy.get('#playlist_edit_button').click()
		cy.get('#playlist_title').type('changed')
		cy.get('#playlist_comment').type('changed')
		cy.contains('Save Changes').click()
		cy.contains('Playlist was successfully updated')
	})

	// is able to change public playlist to private
	it('.edit_access_control()', () => {
		cy.login('administrator')
		cy.visit('/playlists/new')

		cy.get('#playlist_title').type('Cypress Testing5')
		cy.get('#playlist_comment').type('Cypress testing5 comments')
		cy.contains('Public').click()
		cy.get('#submit-playlist-form').click()

		cy.visit('/playlists')
		cy.contains('Cypress Testing5').click()
		cy.contains('Edit Playlist').click()

		cy.get('#playlist_edit_button').click()
		cy.contains('Private').click()
		cy.contains('Save Changes').click()
		cy.contains('Playlist was successfully updated')
		cy.contains('Private')
	})
})
