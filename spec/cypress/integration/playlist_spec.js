/* 
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

import { navigateToManageContent } from '../support/navigation';
context('Playlists', () => {
  //Playlist names start with '_' character for easy navigation without pagination
  var playlist_title = `_Automation playlist title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  // var playlist_title = '_Automation playlist title 20765';
  var playlist_description = `${playlist_title} description`;
  var playlist_title_public = `_Automation public playlist title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  let media_object_id;
  before(() => {
    cy.readFile('cypress.env.dynamic.json').then((data) => {
      media_object_id = Cypress.env('MEDIA_OBJECT_ID', data.MEDIA_OBJECT_ID);
    });
  });
  var playlist_description_public = `${playlist_title_public} description`;

  const media_object_title = Cypress.env('MEDIA_OBJECT_TITLE');

  Cypress.on('uncaught:exception', (err, runnable) => {
    // Prevents Cypress from failing the test due to uncaught exceptions in the application code  - TypeError: Cannot read properties of undefined (reading 'scrollDown')
    if (
      err.message.includes(
        "Cannot read properties of undefined (reading 'success')"
      )
    ) {
      return false;
    }
    if (
      err.message.includes(
        "Cannot read properties of undefined (reading 'times')"
      )
    ) {
      return false;
    }
  });

  //is able to create a new playlist
  it('Verify creating a Playlist - @Tf1b9413d', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.get('#playlists_nav').contains('Playlists').click(); // present in mco-staging as well
    cy.get("[data-testid='playlist-create-new-btn']")
      .contains('Create New Playlist')
      .click();
    cy.get("[data-testid='playlist-title']").type(playlist_title);
    cy.get("[data-testid='playlist-comment']").type(playlist_description);
    cy.intercept('POST', '**/playlists').as('createPlaylist'); //create playlist api
    cy.get("[data-testid='playlist-submit-form']").click();
    //validating the create api
    cy.wait('@createPlaylist').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });

    //Validate play list creation success message
    cy.get("[data-testid='alert']")
      .should('be.visible')
      .within(() => {
        cy.get('p').should('contain', 'Playlist was successfully created.');
      });

    //Validate the newly created playlist page
    // Validate the presence of the video.js element
    cy.get('video[data-testid="videojs-audio-element"]').should('exist');

    // Validate the presence of the text "This playlist currently has no playable items."
    cy.get('[data-testid="inaccessible-message-display"]')
      .should('be.visible')
      .within(() => {
        cy.get('[data-testid="inaccessible-message-content"]').should(
          'contain.text',
          'This playlist currently has no playable items.'
        );
      });

    //validate the playlist details - title, description, buttons , etc
    cy.get('[data-testid="playlist-title"]').get('h1').contains(playlist_title);
    //verify that the  playlist created by default is private
    cy.get('[data-testid="playlist-visibility-icon"]')
      .should('be.visible')
      .and('have.attr', 'title', 'This playlist can only be viewed by you.');
    cy.get('[data-testid="playlist-ramp-description"]').contains(
      playlist_description
    );
    cy.get('[data-testid="playlist-copy-playlist-btn"]').should('be.visible');
    cy.get('[data-testid="auto-advance"]').should('be.visible');
    cy.get('[data-testid="playlist-share-btn"]').should('be.visible');
    cy.get('[data-testid="playlist-edit-playlist-btn"]').should('be.visible');
  });

  //Verify playlist Table View
  it('.validate_playlist_table()', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.visit('/');
    cy.intercept('GET', '/playlists').as('getPlaylists'); //getting the playlists api
    cy.get('#playlists_nav').contains('Playlists').click();

    cy.wait('@getPlaylists').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

    cy.get('#Playlists_filter').within(() => {
      cy.get('input[type="search"]').type(playlist_title);
    });
    cy.get('[ data-testid="playlist-table-head"]')
      .should('be.visible')
      .within(() => {
        cy.contains('Name').should('be.visible');
        cy.contains('Size').should('be.visible');
        cy.contains('Visibility').should('be.visible');
        cy.contains('Created').should('be.visible');
        cy.contains('Updated').should('be.visible');
        cy.contains('Tags').should('be.visible');
        cy.contains('Actions').should('be.visible');
      });

    cy.get('[data-testid="playlist-table-body"] tr')
      .contains('td', playlist_title)
      .closest('tr')
      .within(() => {
        cy.get('td').eq(2).should('contain.text', 'Private'); // Check visibility (Private)
        cy.get('td').eq(6).should('contain.text', 'Copy');
        cy.get('td').eq(6).should('contain.text', 'Edit');
        cy.get('td').eq(6).should('contain.text', 'Delete');
      });
  });

  // Is able to create public playlist
  it('.create_public_playlist()', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.visit('/');

    cy.get('#playlists_nav').contains('Playlists').click(); // present in mco-staging as well
    cy.get("[data-testid='playlist-create-new-btn']")
      .contains('Create New Playlist')
      .click();
    cy.get("[data-testid='playlist-title']").type(playlist_title_public);
    cy.get("[data-testid='playlist-comment']").type(
      playlist_description_public
    );
    cy.contains('Public').click();
    cy.intercept('POST', '**/playlists').as('createPlaylist'); //create api of playlists
    cy.get("[data-testid='playlist-submit-form']").click();
    //validating the api
    cy.wait('@createPlaylist').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });

    cy.contains(playlist_title_public);
    cy.contains('Public');

    cy.get('[data-testid="playlist-visibility-icon"]')
      .should('be.visible')
      .and(
        'have.attr',
        'title',
        'This playlist can be viewed by anyone on the web.'
      );
  });

  //is able to share a public playlist
  it(
    'Verify sharing a public playlist - @c89c89d0',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      cy.get('#playlists_nav').contains('Playlists').click();
      //if in case the created playlist goes on next page
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title_public);
      });
      cy.contains(playlist_title_public).click();
      cy.get('[data-testid="playlist-share-btn"]').click();
      cy.get('[data-testid="playlist-share-list"]').within(() => {
        cy.url().then((currentUrl) => {
          cy.get('[ data-testid="playlist-link"]').should(
            'have.value',
            currentUrl
          );
        });
      });
    }
  );

  // is able to change public playlist to private
  it(
    'Verify editing a playlist from playlist table (Access control) - @T7fa4cea5',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      cy.get('#playlists_nav').contains('Playlists').click();
      //if in case it is on next page
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title_public);
      });
      cy.contains(playlist_title_public).click();
      cy.get('[data-testid="playlist-edit-playlist-btn"]')
        .should('be.visible')
        .click();
      cy.get('[data-testid="playlist-edit-icon-btn"]').click();
      cy.contains('Private').click();
      cy.intercept('POST', '**/playlists/*').as('updatePlaylist'); //update api
      cy.contains('Save Changes').click();
      //validating update api
      cy.wait('@updatePlaylist').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
        expect(interception.response.headers.location).to.include('/edit');
      });
      cy.get('[data-testid="alert"]').contains(
        'Playlist was successfully updated'
      );
      cy.contains('Private');
    }
  );

  // is able to edit playlist name and description
  it(
    'Verify editing a Playlist from playlist page - @T5055855c',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      cy.get('#playlists_nav').contains('Playlists').click();
      //if in case the playlist goes on to the next page
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title_public);
      });
      cy.contains(playlist_title_public).click();
      cy.get('[data-testid="playlist-edit-playlist-btn"]')
        .should('be.visible')
        .click();

      cy.get('[data-testid="playlist-edit-icon-btn"]').click();

      var updated_title = '_Edited' + playlist_title_public;
      var updatedDescription = '_Edited' + playlist_description_public;

      cy.get('[data-testid="playlist-title"]').clear().type(updated_title);
      cy.get('[data-testid="playlist-comment"]')
        .clear()
        .type(updatedDescription);
      //update api - it takes the id of the playlist
      cy.intercept('POST', '**/playlists/*').as('updatePlaylist');
      cy.get('[data-testid="playlist-submit-form"]')
        .contains('Save Changes')
        .click();
      //validating update api
      cy.wait('@updatePlaylist').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
        expect(interception.response.headers.location).to.include('/edit');
      });

      cy.get('[data-testid="alert"]').contains(
        'Playlist was successfully updated'
      );
      cy.get('[data-testid="playlist-details"]')
        .within(() => {
          cy.contains(updated_title).should('be.visible');
          cy.contains(updatedDescription).should('be.visible');
        })
        .then(() => {
          // If assertions pass, update the playlist_title_public
          playlist_title_public = updated_title;
          playlist_description_public = updatedDescription;
          cy.log(`Playlist title updated to: ${playlist_title_public}`); // Log the updated value
        });
    }
  );

  it(
    'Verify adding the current section of an item to a playlist - Create playlist items for each track/subsection - @T3e614dbc',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
      cy.visit('/media_objects/' + media_object_id);
      cy.contains(media_object_title);

      cy.get('[data-testid="media-object-add-to-playlist-btn"]')
        .contains('Add to Playlist')
        .click();
      cy.intercept('POST', '**/add_to_playlist').as('addtoplaylist');
      //Click on the "Current section" radio button
      cy.get('[data-testid="media-object-current-section-radio-btn"]')
        .should('exist')
        .parent()
        .should('contain.text', 'Current Section (')
        .click();
      //Click on dropdown
      cy.get('[data-testid="media-object-playlist-dropdown"]')
        .should('exist')
        .next('span')
        .should('be.visible')
        .click();
      //search
      cy.get('[data-testid="media-object-playlist-search-input"]')
        .should('be.visible')
        .type(playlist_title);
      //click the playlist
      cy.get('[data-testid="media-object-playlist-search-input"]')
        .parent()
        .next()
        .find('li.select2-results__option:not(:first-child)')
        .contains(playlist_title)
        .should('be.visible')
        .click();
      //submit button
      cy.get('[data-testid="media-object-playlist-save-btn"]')
        .should('have.attr', 'value', 'Add')
        .click({ force: true });

      //api validation
      cy.wait('@addtoplaylist').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });

      //verify playlist created success message
      cy.get('[data-testid="media-object-playlist-result-msg"]')
        .should('be.visible')
        .contains('Playlist items created successfully.');
      cy.screenshot();
    }
  );

  it(
    'Verify playlist playback and navigation works as expected',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      cy.get('#playlists_nav').contains('Playlists').click();

      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });

      cy.contains(playlist_title).click();

      cy.get('[data-testid="media-player"]').should('exist');
      cy.waitForVideoReady();

      // Play the first item manually
      cy.get('.current-time-display')
        .should('be.visible')
        .invoke('text')
        .then((initialTime) => {
          cy.get('button[title="Play"]').click();
          cy.wait(3000);
          cy.get('.current-time-display')
            .invoke('text')
            .should((currentTime) => {
              expect(currentTime).to.not.equal(initialTime);
            });
        });

      // For next items in playlist autoplay is ON
      const clickAndAutoplayCheck = (index) => {
        cy.get('[data-testid="list-item"]').eq(index).scrollIntoView().click();

        cy.waitForVideoReady();

        // Take note of initial time. play the item. note the current time and compare with initial time
        cy.get('.current-time-display')
          .invoke('text')
          .then((initialTime) => {
            cy.wait(3000); // Let it autoplay
            cy.get('.current-time-display')
              .invoke('text')
              .should((currentTime) => {
                expect(currentTime).to.not.equal(initialTime);
              });
          });
      };

      // Autoplay test for next 2 items
      clickAndAutoplayCheck(1);
      clickAndAutoplayCheck(2);

      // Next button
      cy.get('[data-testid="videojs-next-button"]').click();
      cy.waitForVideoReady();
      cy.get('.current-time-display')
        .invoke('text')
        .then((initialTime) => {
          cy.wait(3000);
          cy.get('.current-time-display')
            .invoke('text')
            .should((currentTime) => {
              expect(currentTime).to.not.equal(initialTime);
            });
        });

      // Previous button
      cy.get('[data-testid="videojs-previous-button"]').click();
      cy.waitForVideoReady();
      cy.get('.current-time-display')
        .invoke('text')
        .then((initialTime) => {
          cy.wait(3000);
          cy.get('.current-time-display')
            .invoke('text')
            .should((currentTime) => {
              expect(currentTime).to.not.equal(initialTime);
            });
        });

      // some video player checks
      cy.get('button[title="Mute"]').should('exist');
      cy.get('button[title="Fullscreen"]').should('exist');
    }
  );

  it('Verify deleting items in the playlist', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.visit('/');
    cy.get('#playlists_nav').contains('Playlists').click();
    //if in case the playlist goes on to the next page
    cy.get('#Playlists_filter').within(() => {
      cy.get('input[type="search"]').type(playlist_title);
    });
    cy.contains(playlist_title).click();
    cy.get('[data-testid="playlist-edit-playlist-btn"]')
      .should('be.visible')
      .click();

    cy.get('[data-testid="playlist-edit-icon-btn"]').click(); //edit button on the playlist
    cy.get('[data-testid^="playlist-item-checkbox"]').first().check(); //selecting the first item in the playlist
    cy.get('[data-testid="playlist-delete-selected-btn"]')
      .should('not.be.disabled')
      .click(); // clicking on delete selected button
    cy.intercept('POST', '**/update_multiple').as('deleteiteminplaylist');
    cy.contains('Yes, Delete').should('be.visible').click();
    cy.wait('@deleteiteminplaylist').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });
    cy.get('[data-testid="alert"]')
      .contains('Playlist was successfully updated.')
      .should('be.visible');
    //can check if the item was deleted
  });

  it(
    'Verify the "add to playlist" button behavior - @Tcdb5ac47',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
      cy.visit('/media_objects/' + media_object_id);
      cy.contains(media_object_title);
      cy.get('[data-testid="media-object-add-to-playlist-btn"]')
        .contains('Add to Playlist')
        .click();
      //Validate the "Add to playlist options"
      cy.get('[ data-testid="media-object-add-to-playlist-form"]').within(
        () => {
          cy.get('[data-testid="media-object-current-track-radio-btn"]')
            .should('exist')
            .parent()
            .should('contain.text', 'Current Track (');
          cy.get('[ data-testid="media-object-custom-timespan-radio-btn"]')
            .should('exist')
            .parent()
            .should('contain.text', 'Custom Timespan');
          cy.get('[data-testid="media-object-current-section-radio-btn"]')
            .should('exist')
            .parent()
            .should('contain.text', 'Current Section (');
          cy.get('[data-testid="media-object-all-section-radio-btn"]')
            .should('exist')
            .parent()
            .should('contain.text', 'All Sections');
        }
      );

      //Validate Playlist dropdown
      cy.get('[data-testid="media-object-playlist-dropdown"]')
        .next('span')
        .click();

      //Validate add new playlist option in the dropdown
      cy.get('[data-testid="media-object-playlist-search-input"]')
        .parent()
        .next()
        .contains('Add new playlist')
        .should('be.visible');

      //Validate search for playlist within the playlist dropdown
      cy.get('[data-testid="media-object-playlist-search-input"]').type(
        playlist_title
      );
      cy.get('[data-testid="media-object-playlist-search-input"]')
        .parent()
        .next()
        .contains('b', playlist_title)
        .should('be.visible');
    }
  );

  // Teardown codes  to delete playlist_title and playlist_title_public

  // deletes playlist permanently from playlists table
  //The "playlist_title" playlist gets deleted here
  it(
    'Verify Deleting a Playlist - playlist table - @T53c3887a',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      cy.intercept('POST', '**/playlists/*').as('deleteplaylist');

      cy.visit('/playlists');
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });
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

      //Add more assertions here
      //Handle pagination case - search for the playlist - it should not appear. Add  API validation

      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });
      cy.get('[data-testid="playlist-table-body"] tr')
        .contains(playlist_title)
        .should('not.exist');
    }
  );

  // is able to delete playlist from edit playlist page
  //The "playlist_title_public" playlist gets deleted here
  it(
    'Verify Deleting a Playlist - playlist page - @T49ac05b8',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      cy.visit('/playlists');
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title_public);
      });
      cy.contains(playlist_title_public).click();
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
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title_public);
      });
      cy.get('[data-testid="playlist-table-body"] tr')
        .contains(playlist_title_public)
        .should('not.exist');
    }
  );

  //Clean up code for item and collection created across spec

  it('Verify deleting an item - @Tf46071b7', { tags: '@critical' }, () => {
    cy.login('administrator');

    cy.visit('/media_objects/' + media_object_id);
    cy.waitForVideoReady();
    cy.get('[data-testid="media-object-edit-btn"]').contains('Edit').click();
    cy.intercept('POST', '/media_objects/**').as('removeMediaObject');
    cy.get('[data-testid="media-object-delete-btn"]')
      .contains('Delete this item')
      .click();
    cy.get('[data-testid="media-object-delete-confirmation-btn"]')
      .contains('Yes, I am sure')
      .click();
    cy.wait('@removeMediaObject').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });
    cy.get('[data-testid="alert"]').contains('1 media object deleted.');
  });

  it('Verify deleting a collection - @T959a56df', { tags: '@critical' }, () => {
    var search_collection = Cypress.env('SEARCH_COLLECTION');
    cy.login('administrator');
    cy.visit('/');
    navigateToManageContent();
    cy.get("[data-testid='collection-name-table']")
      .contains(search_collection)
      .closest('tr')
      .find("[data-testid='collection-delete-collection-btn']")
      .click();
    cy.intercept('POST', `/admin/collections/*`).as('deleteCollection');
    //May require adding steps to select a collection to move the existing  items, when dealing with non empty collections
    cy.get("[data-testid='collection-delete-confirm-btn']").click();
    cy.wait('@deleteCollection').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include(
        '/admin/collections'
      );
    });
    navigateToManageContent();
    //May need to update this assertion to ensure that this is valid during pagination of collections. Another alternative would be to check via API or search My collections
    cy.get("[data-testid='collection-name-table']")
      .contains(search_collection)
      .should('not.exist');
  });
});
