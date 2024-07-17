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
	// var playlist_title = `_Automation playlist title ${Math.floor(Math.random() * 10000) + 1
	// 	}`;
	var playlist_title=	"_Automation playlist title 2086"
	var playlist_description = `${playlist_title} description`;
	var playlist_title_public = `_Automation public playlist title ${Math.floor(Math.random() * 10000) + 1
		}`;
	var playlist_description_public = `${playlist_title_public} description`;
	const media_object_id = Cypress.env('MEDIA_OBJECT_ID_2')
	const media_object_title = Cypress.env('MEDIA_OBJECT_TITLE_2')

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

	it('Verify the "add to playlist" button behavior - @Tcdb5ac47', () => {
		cy.login('administrator')
		cy.visit('/')
		// The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
		cy.visit('/media_objects/' + media_object_id)
		cy.contains(media_object_title)
		cy.get('#addToPlaylistBtn').click();
		//Validate the "Add to playlist options"
		cy.get('#add-to-playlist-form-group')
          .within(() => {
			cy.contains('label.form-check-label', 'Custom Timespan').get('input[type="radio"]')
			cy.contains('label.form-check-label', 'Current Track ()').get('input[type="radio"]')
			cy.contains('label.form-check-label', 'Current Section ').get('input[type="radio"]')
			cy.contains('label.form-check-label', 'All Sections').get('input[type="radio"]')
          });
		
		//Validate Playlist dropdown
		cy.get("#select2-post_playlist_id-container").click()
		
		cy.get("span.select2-dropdown").within(()=>{
			cy.get('ul.select2-results__options li')
      .contains('Add new playlist')
      .should('be.visible');
	  //Validate search for playlist within the playlist dropdown
	  cy.get('span.select2-search input.select2-search__field')
      .type(playlist_title)
	  cy.get('span.select2-results')
      .contains('b', playlist_title)
      .should('be.visible');
		})
		
  });

  it.only('Verify adding the current section of an item to a playlist - Create playlist items for each track/subsection - @T3e614dbc', () => {
	cy.login('administrator')
	cy.visit('/')
	// The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
	cy.visit('/media_objects/' + media_object_id)
	cy.contains(media_object_title)
	cy.get('#addToPlaylistBtn').click();

	 //Click on the "Current section" radio button
	 cy.get('#playlistitem_scope_section').should('be.visible').click();
	
	//Open Playlist dropdown
	cy.get("#select2-post_playlist_id-container").click()

  //Validate search for playlist within the playlist dropdown
  cy.get('span.select2-search input.select2-search__field')
  .type(playlist_title)
  cy.get('span.select2-results')
  .contains('b', playlist_title)
  .should('be.visible');
	
//Click on the playlist_title from search 
cy.get('ul#select2-post_playlist_id-results').within(() => {
	cy.contains('li.select2-results__option', '_Automation playlist title 2086').eq(1).click();
  });
cy.get('#addToPlaylistSave').click();

//verify playlist created success message
cy.get('#add_to_playlist_result_message')
  .should('be.visible')
  .should('contain.text', 'Playlist items created successfully.');
cy.screenshot()

});

		
	// Teardown codes  to delete playlist_title and playlist_title_public

	// deletes playlist permanently from playlists table
	//The "playlist_title" playlist gets deleted here
	it('Verify Deleting a Playlist - playlist table - @T53c3887a', () => {
		cy.login('administrator');
		cy.visit('/');

		cy.visit('/playlists');
		cy.get('tr')
			.contains('td', playlist_title)
			.parent('tr')
			.find('.btn-danger')
			.click();
		cy.contains('Yes, Delete').click();

		cy.visit('/playlists');

		//Add more assertions here
		//Handle pagination case - search for the playlist - it should not appear. Add  API validation
		cy.contains(playlist_title).should('not.exist');
	});

	// is able to delete playlist from edit playlist page
	//The "playlist_title_public" playlist gets deleted here
	it('Verify Deleting a Playlist - playlist page - @T49ac05b8', () => {
		cy.login('user');
		cy.visit('/');

		cy.visit('/playlists');
		cy.contains(playlist_title_public).click();
		cy.contains('Edit Playlist').click();

		cy.contains('Delete Playlist').click();
		cy.contains('Yes, Delete').click();
		cy.contains('Playlist was successfully destroyed.');
		cy.visit('/playlists');

		//Add more assertions here
		//Handle pagination case - search for the playlist - it should not appear. Add  API validation
		cy.contains(playlist_title_public).should('not.exist');
	});

	
});
