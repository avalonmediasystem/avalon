/*
 * Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

class PlaylistPage {
  navigateToPlaylist(playlist_title) {
    cy.get('#playlists_nav').contains('Playlists').click(); // present in mco-staging as well
    cy.get('[data-testid="playlist-table-search-field"]')
      .clear()
      .type(playlist_title);
    cy.get("[data-testid='playlist-name-table']")
      .contains(playlist_title)
      .click();
    cy.url().should('include', '/playlists/');
  }

  createPlaylist(playlistData, options = {}) {
    const defaults = {
      description: 'Playlist desc',
      visibility: 'private',
    };

    const config = { ...defaults, ...playlistData, ...options };

    cy.get('#playlists_nav').contains('Playlists').click(); // present in mco-staging as well
    cy.get("[data-testid='playlist-create-new-btn']")
      .contains('Create New Playlist')
      .click();
    cy.get("[data-testid='playlist-title']").type(config.title).should('have.value', config.title);
    cy.get("[data-testid='playlist-comment']").type(config.description).should('have.value', config.description);
    cy.get(`#playlist_visibility_${config.visibility}`).click();
    cy.get("input[name='playlist[visibility]']:checked").should('have.value', config.visibility);
    cy.intercept('POST', '**/playlists').as('createPlaylist'); //create playlist api
    cy.get("[data-testid='playlist-submit-form']").click();
    //validating the create api
    cy.wait('@createPlaylist').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include('/playlists/');
    });

    //Validate play list creation success message
    cy.get("[data-testid='alert']")
      .should('be.visible')
      .within(() => {
        cy.get('p').should('contain', 'Playlist was successfully created.');
      });

    cy.get('[data-testid="playlist-title"]').get('h1').contains(config.title);
    cy.get('[data-testid="playlist-ramp-description"]').contains(config.description);
    switch (config.visibility) {
      case 'private':
	cy.get('[data-testid="playlist-visibility-icon"]')
	  .should('be.visible')
	  .and('have.attr', 'title', 'This playlist can only be viewed by you.');
	break;
      case 'private-with-token':
	cy.get('[data-testid="playlist-visibility-icon"]')
	  .should('be.visible')
	  .and('have.attr', 'title', 'This playlist can only be viewed by users who have the unique link.');
	break;
      case 'public':
	cy.get('[data-testid="playlist-visibility-icon"]')
	  .should('be.visible')
	  .and('have.attr', 'title', 'This playlist can be viewed by anyone on the web.');
	break;
    }

    cy.wrap(config.title);
  }

  setVisibility(visibility) {
    cy.get('[data-testid="playlist-edit-icon-btn"]').click();
    cy.get(`#playlist_visibility_${visibility}`).click();
    cy.get("input[name='playlist[visibility]']:checked").should('have.value', visibility);
    cy.intercept('POST', '**/playlists/*').as('updatePlaylist'); //update api
    cy.contains('Save Changes').click();
    //validating update api
    cy.wait('@updatePlaylist').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include('/edit');
    });
    cy.get('[data-testid="alert"]').contains(
      'Playlist was successfully updated',
    );
    switch (visibility) {
      case 'private':
	cy.get('[data-testid="playlist-visibility-icon"]')
	  .should('be.visible')
	  .and('have.attr', 'title', 'This playlist can only be viewed by you.');
	break;
      case 'private-with-token':
	cy.get('[data-testid="playlist-visibility-icon"]')
	  .should('be.visible')
	  .and('have.attr', 'title', 'This playlist can only be viewed by users who have the unique link.');
	break;
      case 'public':
	cy.get('[data-testid="playlist-visibility-icon"]')
	  .should('be.visible')
	  .and('have.attr', 'title', 'This playlist can be viewed by anyone on the web.');
	break;
    }
  }

  deletePlaylistFromTable(playlist_title) {
    cy.intercept('POST', '**/playlists/*').as('deleteplaylist');

    cy.visit('/playlists');
    cy.get('[data-testid="playlist-table-search-field"]').type(
      playlist_title,
    );
    cy.get('[data-testid="playlist-table-body"] tr')
      .contains('td', playlist_title)
      .closest('tr')
      .within(() => {
	cy.get('[data-testid="playlist-delete-table-view"]')
	  .should('contain.text', 'Delete')
	  .click();
      });
    cy.contains('Yes, Delete').click();
    cy.wait('@deleteplaylist').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
    cy.get('[data-testid="alert"]')
      .contains('Playlist was successfully destroyed.')
      .should('be.visible');
    cy.visit('/playlists');

    cy.get('[data-testid="playlist-table-search-field"]').type(
      playlist_title,
    );
    cy.get('[data-testid="playlist-table-body"] tr')
      .contains(playlist_title)
      .should('not.exist');
  }

  deletePlaylistFromPage(playlist_title) {
    this.navigateToPlaylist(playlist_title);
    cy.get('[data-testid="playlist-edit-playlist-btn"]').click();
    cy.intercept('POST', '**/playlists/*').as('deleteplaylist'); //delete api
    cy.get('[data-testid="playlist-delete-playlist-form"]')
      .contains('Delete Playlist')
      .click();
    cy.contains('Yes, Delete').click();
    cy.wait('@deleteplaylist').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include('/playlists');
    });
    cy.get('[data-testid="alert"]')
      .contains('Playlist was successfully destroyed.')
      .should('be.visible');
    cy.visit('/playlists');

    //Add more assertions here
    //Handle pagination case - search for the playlist - it should not appear. Add  API validation
    cy.get('[data-testid="playlist-table-search-field"]').type(
      playlist_title,
    );
    cy.get('[data-testid="playlist-table-body"] tr')
      .contains(playlist_title)
      .should('not.exist');
  }
}

export default PlaylistPage;
