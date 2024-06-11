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
	//Playlist names start with '_' character for easy navigation without pagination
	var playlist_title = `_Automation playlist title ${Math.floor(Math.random() * 10000) + 1
		}`;
	var playlist_description = `${playlist_title} description`;
	var playlist_title_public = `_Automation public playlist title ${Math.floor(Math.random() * 10000) + 1
		}`;
	var playlist_description_public = `${playlist_title_public} description`;

	Cypress.on('uncaught:exception', (err, runnable) => {
		// Prevents Cypress from failing the test due to uncaught exceptions in the application code  - TypeError: Cannot read properties of undefined (reading 'scrollDown')
		if (
			err.message.includes(
				"Cannot read properties of undefined (reading 'success')"
			)
		) {
			return false;
		}
	});

	//checks navigation when create new playlist is accessed
	it('.create_playlists()', () => {
		cy.login('administrator');
		cy.visit('/playlists/new');
	});

	//is able to create a new playlist
	it('Verify creating a Playlist - @Tf1b9413d', () => {
		cy.login('administrator');
		cy.visit('/');
		cy.get('#playlists_nav').click();
		cy.get('a[href="/playlists/new"]').click();

		cy.get('#playlist_title').type(playlist_title);
		cy.get('#playlist_comment').type(playlist_description);
		cy.get('#submit-playlist-form').click();

		//Validate play list creation success message
		cy.get('.alert.alert-info')
			.should('be.visible')
			.within(() => {
				cy.get('p').should('contain', 'Playlist was successfully created.');
			});

		//Validate the newly created playlist page
		// Validate the presence of the video.js element
		cy.get('video[data-testid="videojs-audio-element"]')
			.should('exist')
			.and('have.class', 'video-js')
			.and('have.class', 'vjs-big-play-centered');

		// Validate the presence of the text "This playlist currently has no playable items."
		cy.get('div[data-testid="inaccessible-message-display"] p')
			.should('be.visible')
			.and('contain.text', 'This playlist currently has no playable items.');

		//validate the playlist details - title, description, buttons , etc
		cy.get('div.playlist-title').get('h1').contains(playlist_title);
		//verify that the  playlist created by default is private
		cy.get('div.playlist-title')
			.find('span[title="This playlist can only be viewed by you."]')
			.should('be.visible');
		cy.contains('h4', 'Description')
			.should('be.visible')
			.next('p')
			.should('have.text', playlist_description);
		cy.get('button.copy-playlist-button').should('be.visible');
		cy.get('div.ramp--auto-advance').should('be.visible');
		cy.get('#share-button').should('be.visible');
		cy.get('#edit-playlist-button').should('be.visible');
	});

	it('.validate_playlist_table()', () => {
		cy.login('administrator');
		cy.visit('/');
		cy.get('#playlists_nav').click();
		cy.visit('/playlists');
		cy.contains('Name');
		cy.contains('Visibility');
		cy.contains('Created');
		cy.contains('Updated');
		cy.contains('Actions');
		cy.contains('Private');
		cy.contains('Size');
		cy.contains('Delete');
		cy.contains('Edit');
	});


	// deletes playlist permanently from playlists page
	it('Verify Deleting a Playlist - playlist table - @T53c3887a', () => {
		cy.login('administrator');
		cy.visit('/');
		var playlist_title_1 = `__Automation playlist title ${Math.floor(Math.random() * 10000) + 1
			}`;
		var playlist_description_1 = `${playlist_title} description`;

		cy.get('#playlists_nav').click();
		cy.get('a[href="/playlists/new"]').click();
		cy.get('#playlist_title').type(playlist_title_1);
		cy.get('#playlist_comment').type(playlist_description_1);
		cy.get('#submit-playlist-form').click();

		cy.visit('/playlists');
		cy.get('tr')
			.contains('td', playlist_title_1)
			.parent('tr')
			.find('.btn-danger')
			.click();
		cy.contains('Yes, Delete').click();

		cy.visit('/playlists');

		//Handle pagination case - search for the playlist. Add  API validation
		cy.contains(playlist_title).should('not.exist');
	});

	// is able to delete playlist from edit playlist page
	it('Verify Deleting a Playlist - playlist page - @T49ac05b8', () => {
		cy.login('user');
		cy.visit('/');
		var playlist_title = `__Automation playlist title ${Math.floor(Math.random() * 10000) + 1
			}`;
		var playlist_description = `${playlist_title} description`;

		cy.get('#playlists_nav').click();
		cy.get('a[href="/playlists/new"]').click();
		cy.get('#playlist_title').type(playlist_title);
		cy.get('#playlist_comment').type(playlist_description);
		cy.get('#submit-playlist-form').click();

		cy.visit('/playlists');
		cy.contains(playlist_title).click();
		cy.contains('Edit Playlist').click();

		cy.contains('Delete Playlist').click();
		cy.contains('Yes, Delete').click();
		cy.contains('Playlist was successfully destroyed.');
		cy.visit('/playlists');
		cy.contains(playlist_title).should('not.exist');
	});

	// is able to create public playlist
	it('.create_public_playlist()', () => {
		cy.login('administrator');
		cy.visit('/');

		cy.get('#playlists_nav').click();
		cy.get('a[href="/playlists/new"]').click();
		// cy.visit('/playlists/new')

		cy.get('#playlist_title').type(playlist_title_public);
		cy.get('#playlist_comment').type(playlist_description_public);
		cy.contains('Public').click();
		cy.get('#submit-playlist-form').click();

		cy.visit('/playlists');
		cy.contains(playlist_title_public);
		cy.contains(playlist_description_public);
		cy.contains('Public');
		cy.get('div.playlist-title')
			.find('span[title="This playlist can be viewed by anyone on the web."]')
			.should('be.visible');
	});

	//is able to share a public playlist
	it('Verify sharing a public playlist - @c89c89d0', () => {
		cy.login('administrator');
		cy.visit('/');
		cy.get('#playlists_nav').click();
		cy.contains(playlist_title_public).click();
		cy.get('#share-button').click()
		cy.get('#share-list').within(()=>{
			cy.url().then((currentUrl) => {
				cy.get('#link-object') 
				  .should('have.value', currentUrl);
			  });
		})
	});

	// is able to change public playlist to private
	it('Verify editing a playlist from playlist table (Access control) - @T7fa4cea5', () => {
		cy.login('administrator')
		cy.visit('/')
		// cy.visit('/playlists/new')
		cy.get('#playlists_nav').click()
		cy.get('tr')
			.contains('td', playlist_title_public)
			.parent('tr')
			.contains('Edit')
			.click();
		cy.screenshot()
		cy.get('#playlist_edit_button').click()
		cy.contains('Private').click()
		cy.contains('Save Changes').click()
		cy.contains('Playlist was successfully updated')
		cy.contains('Private')
	})

	// is able to edit playlist name and description
	it('Verify editing a Playlist from playlist page - @T5055855c', () => {
		cy.login('administrator')
		cy.visit('/playlists')

		cy.contains(playlist_title_public).click()
		cy.contains('Edit Playlist').click()

		cy.get('#playlist_edit_button').click()
		
		var updated_title = "_Edited" + playlist_title_public
		var updatedDescription = "_Edited" + playlist_description_public

		cy.get('#playlist_title').clear().type(updated_title)
		cy.get('#playlist_comment').clear().type(updatedDescription)
		cy.contains('Save Changes').click()
		cy.contains('Playlist was successfully updated')
		cy.get('#playlist_view_div').within(() => {
			cy.contains('dd',updated_title)
			cy.contains('dd', updatedDescription)
			  }).then(() => {
				// If assertions pass, update the playlist_title_public
				playlist_title_public = updated_title;
				playlist_description_public = updatedDescription
				cy.log(`Playlist title updated to: ${playlist_title_public}`); // Log the updated value
			  });
	})


	//Add teardown code here to delete playlist_title and playlist_title_public

	
});
