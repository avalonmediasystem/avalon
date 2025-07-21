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
import CollectionPage from '../pageObjects/collectionPage';
import HomePage from '../pageObjects/homePage';
const homePage = new HomePage();

context('Playlists', () => {
  const collectionPage = new CollectionPage();

  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var media_object_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;
  var media_object_id;
  var share_by_link_playlist;

  //Playlist names start with '_' character for easy navigation without pagination
  var playlist_title = `_Automation playlist title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  // var playlist_title = '_Automation playlist title 20765';
  var playlist_description = `${playlist_title} description`;
  var playlist_title_public = `_Automation public playlist title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var playlist_description_public = `${playlist_title_public} description`;
  Cypress.on('uncaught:exception', (err, runnable) => {
    if (
      err.message.includes(
        "Cannot read properties of undefined (reading 'success')"
      ) ||
      err.message.includes(
        "Cannot read properties of undefined (reading 'times')"
      )
    ) {
      return false;
    }
  });

  // Create collection and complex media object before all tests
  before(() => {
    cy.login('administrator');
    navigateToManageContent();

    // Create collection with public access
    collectionPage.createCollection(
      { title: collection_title },
      { setPublicAccess: false }
    );

    // Navigate to the collection and create complex media object
    collectionPage.navigateToCollection(collection_title);

    collectionPage.createComplexMediaObject(media_object_title, {
      publish: true,
      addStructure: true,
    });

    // Get the media object ID from the alias
    cy.get('@mediaObjectId').then((id) => {
      media_object_id = id;
    });
  });

  // Clean up after all tests - ITEM FIRST, THEN COLLECTION
  // Clean up after all tests - ITEM FIRST, THEN COLLECTION
  after(() => {
    cy.login('administrator');

    // Delete the media object first (if it exists)
    if (media_object_id) {
      collectionPage.deleteItemById(media_object_id);
    }

    // Then delete the collection
    collectionPage.deleteCollectionByName(collection_title);
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
    'Verify adding the track section of an item to a playlist - @T3e614dbc',
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
      cy.intercept('POST', '**/items').as('addtoplaylist');
      //Click on the "Current section" radio button
      cy.get('[data-testid="media-object-current-track-radio-btn"]')
        .should('exist')
        .parent()
        .should('contain.text', 'Current Track (')
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
        .type(playlist_title_public);
      //click the playlist
      cy.get('[data-testid="media-object-playlist-search-input"]')
        .parent()
        .next()
        .find('li.select2-results__option:not(:first-child)')
        .contains(playlist_title_public)
        .should('be.visible')
        .click();
      //submit button
      cy.get('[data-testid="media-object-playlist-save-btn"]')
        .should('have.attr', 'value', 'Add')
        .click({ force: true });

      //api validation
      cy.wait('@addtoplaylist').then((interception) => {
        expect(interception.response.statusCode).to.eq(201);
      });

      //verify playlist created success message
      cy.get('[data-testid="media-object-playlist-result-msg"]')
        .should('be.visible')
        .contains('Add to playlist was successful.');
      cy.screenshot();
    }
  );

  it(
    'Verifies playlist autoplay toggle and playback behavior',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      // Navigate to Playlists
      cy.get('#playlists_nav').contains('Playlists').click();

      // Search and open a specific playlist
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });

      cy.contains(playlist_title).click();
      cy.get('[data-testid="media-player"]').should('exist');
      cy.waitForVideoReady();

      // Autoplay is turned on
      cy.get('[data-testid="auto-advance"]').should(
        'have.attr',
        'aria-checked',
        'true'
      );

      // Play first item
      cy.get('[data-testid="tree-item"]').eq(0).click();
      cy.waitForVideoReady();

      // Hover to expose controls, then Play
      cy.get('button[title="Play"]').click();
      cy.wait(10000);
      // Wait for structured-nav to switch to 2nd item
      cy.get('[data-testid="tree-item"]').eq(1).should('have.class', 'active');

      // autoplay turned off
      cy.get('[data-testid="auto-advance-toggle"]').click();
      cy.get('[data-testid="auto-advance"]').should(
        'have.attr',
        'aria-checked',
        'false'
      );

      // Play second item
      cy.get('[data-testid="tree-item"]').eq(1).click();
      cy.waitForVideoReady();
      cy.get('video').scrollIntoView().trigger('mouseover');
      cy.get('button[title="Play"]').click();

      // Wait 10 seconds and confirm section does not auto-advance
      cy.wait(20000);
      cy.get('[data-testid="tree-item"]').eq(1).should('have.class', 'active');

      cy.get('[data-testid="tree-item"]')
        .eq(2)
        .should('not.have.class', 'active');
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
          cy.get('.video-js').trigger('mousemove', { force: true });
          cy.get('.current-time-display')
            .invoke('text')
            .should((currentTime) => {
              expect(currentTime).to.not.equal(initialTime);
            });
        });

      // Function to click structured playlist items and verify playback
      const clickAndAutoplayCheck = (index) => {
        cy.get('[data-testid="tree-item"]')
          .eq(index)
          .scrollIntoView()
          .find('a.ramp--structured-nav__item-link')
          .click();

        cy.waitForVideoReady();

        cy.get('.current-time-display')
          .invoke('text')
          .then((initialTime) => {
            cy.wait(3000); // Let it autoplay a bit
            cy.get('.video-js').trigger('mousemove', { force: true });
            cy.get('.current-time-display')
              .invoke('text')
              .should((currentTime) => {
                expect(currentTime).to.not.equal(initialTime);
              });
          });
      };

      // Autoplay test for next 2 items
      clickAndAutoplayCheck(1); // "Part 2"
      cy.get('.video-js').trigger('mousemove', { force: true });
      // Next button
      cy.get('[data-testid="videojs-next-button"]').click();
      cy.waitForVideoReady();
      cy.get('.current-time-display')
        .invoke('text')
        .then((initialTime) => {
          cy.wait(3000);
          cy.get('.video-js').trigger('mousemove', { force: true });
          cy.get('.current-time-display')
            .invoke('text')
            .should((currentTime) => {
              expect(currentTime).to.not.equal(initialTime);
            });
        });
      cy.get('.video-js').trigger('mousemove', { force: true });
      // Previous button
      cy.get('[data-testid="videojs-previous-button"]').click();
      cy.waitForVideoReady();
      cy.get('.current-time-display')
        .invoke('text')
        .then((initialTime) => {
          cy.wait(3000);
          cy.get('.video-js').trigger('mousemove', { force: true });
          cy.get('.current-time-display')
            .invoke('text')
            .should((currentTime) => {
              expect(currentTime).to.not.equal(initialTime);
            });
        });

      //Basic player button checks
      cy.get('button[title="Mute"]').should('exist');
      cy.get('button[title="Fullscreen"]').should('exist');
    }
  );

  it(
    'Verifies adding a marker and playback behavior from marker position',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      // Navigate to Playlists
      cy.get('#playlists_nav').contains('Playlists').click();

      // Search and open playlist
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });

      cy.contains(playlist_title).click();
      cy.get('[data-testid="media-player"]').should('exist');
      cy.waitForVideoReady();

      // Open Markers accordion and click "Add New Marker"
      cy.contains('button', 'Markers').click();
      cy.get('[data-testid="create-new-marker-button"]').click();

      // Fill marker title and time
      const markerTitle = 'Test Marker';
      const markerTime = '00:00:05.000';
      const markerTimeSec = 5;

      cy.get('[data-testid="create-marker-title"]').clear().type(markerTitle);
      cy.get('[data-testid="create-marker-timestamp"]')
        .clear()
        .type(markerTime);
      cy.get('[data-testid="edit-save-button"]').click();

      // Verify table header
      cy.get('[data-testid="markers-display-table"] thead tr').within(() => {
        cy.get('th').eq(0).should('have.text', 'Name');
        cy.get('th').eq(1).should('have.text', 'Time');
        cy.get('th').eq(2).should('have.text', 'Actions');
      });

      // Verify row content
      cy.get('[data-testid="markers-display-table"] tbody tr')
        .first()
        .within(() => {
          cy.get('td').eq(0).find('a').should('have.text', markerTitle);
          cy.get('td').eq(1).should('have.text', markerTime);
          cy.get('[data-testid="edit-button"]').should('exist');
          cy.get('[data-testid="delete-button"]').should('exist');
        });

      // Verify marker on progress bar
      cy.get('[data-testid="videojs-custom-seekbar"]')
        .find(`[data-marker-time="${markerTimeSec}"]`)
        .should('exist');

      // Click marker on progress bar
      cy.get(`[data-marker-time="${markerTimeSec}"]`).click({ force: true });

      // Unpause and confirm playhead moves near marker
      cy.get('button[title="Play"]').click();
      cy.get('video').then(($video) => {
        const currentTime = $video[0].currentTime;
        expect(currentTime).to.be.closeTo(markerTimeSec, 2);
      });

      // Click marker in table and confirm playhead again
      cy.get('[data-testid="markers-display-table"] tbody tr')
        .first()
        .find('td')
        .eq(0)
        .find('a')
        .click();

      cy.get('video').then(($video) => {
        const currentTime = $video[0].currentTime;
        expect(currentTime).to.be.closeTo(markerTimeSec, 2);
      });
    }
  );
  it(
    'Verify editing markers to an item in playlist - @T72550101',
    { tags: '@critical' },
    () => {
      const updatedTitle = 'Updated Marker Title';
      const updatedOffset = '00:00:03.000';
      const updatedSeconds = 3;

      cy.login('administrator');
      cy.visit('/');

      // Navigate to Playlists
      cy.get('#playlists_nav').contains('Playlists').click();

      // Search and open playlist
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });

      cy.contains(playlist_title).click();
      cy.get('[data-testid="media-player"]').should('exist');
      cy.waitForVideoReady();

      // Open Markers tile
      cy.contains('button', 'Markers').click();

      // Click edit button on first marker row
      cy.get('[data-testid="markers-display-table"] tbody tr')
        .first()
        .within(() => {
          cy.get('[data-testid="edit-button"]').click();
        });

      // Update marker title and time
      cy.get('[data-testid="edit-label"]').clear().type(updatedTitle);
      cy.get('[data-testid="edit-timestamp"]').clear().type(updatedOffset);
      cy.get('[data-testid="edit-save-button"]').click();

      // Verify the updated row contents
      cy.get('[data-testid="markers-display-table"] tbody tr')
        .first()
        .within(() => {
          cy.get('td').eq(0).find('a').should('contain.text', updatedTitle);
          cy.get('td').eq(1).should('contain.text', updatedOffset);
        });

      // Verify the visual marker dot exists with updated time
      cy.get('[data-testid="videojs-custom-seekbar"]')
        .find(`[data-marker-time="${updatedSeconds}"]`)
        .should('exist')
        .click({ force: true });

      // Trigger hover so controls are visible
      cy.get('[data-testid="media-player"]').trigger('mouseover', {
        force: true,
      });

      // Click play
      cy.get('button[title="Play"]').click();

      // Wait and verify playback started near 3s

      cy.get('video').then(($video) => {
        const current = $video[0].currentTime;
        expect(current).to.be.closeTo(updatedSeconds, 1.5);
      });

      // Click on the marker title in the table to jump
      cy.get('[data-testid="markers-display-table"] tbody tr')
        .first()
        .find('td')
        .eq(0)
        .find('a')
        .click();

      cy.get('video').then(($video) => {
        const current = $video[0].currentTime;
        expect(current).to.be.closeTo(updatedSeconds, 1.5);
      });
    }
  );

  it(
    'Verify Deleting markers to an item in playlist - @T058c6ad3',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      // Go to Playlists
      cy.get('#playlists_nav').contains('Playlists').click();

      // Search for the playlist
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });

      // Open the playlist
      cy.contains(playlist_title).click();
      cy.get('[data-testid="media-player"]').should('exist');
      cy.waitForVideoReady();

      // Open the Markers panel
      cy.contains('button', 'Markers').click();
      cy.get('[data-testid="delete-button"]').click();
      // Confirm deletion by clicking "Yes"
      cy.get('[data-testid="delete-confirm-button"]').click();

      // Ensure the marker no longer appears in the table
      // Confirm marker table no longer exists
      cy.get('[data-testid="markers-display-table"]').should('not.exist');

      // Confirm the seekbar marker is also removed
      cy.get('[data-marker-time]').should('not.exist');

      // Confirm that "Add New Marker" button still exists
      cy.get('[data-testid="annotations-display"]').within(() => {
        cy.get('[data-testid="create-new-marker-button"]').should('exist');
      });
    }
  );

  it(
    'Verify that private playlists cannot be shared - @Ta1984bd6',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.get('#playlists_nav').contains('Playlists').click();

      // Search and open playlist
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });
      cy.contains(playlist_title).click();

      // Share tab message saying that the playlist cannot be shared
      cy.get('[data-testid="playlist-share-btn"]').click();
      cy.get('[data-testid="playlist-link"]').should(
        'contain.text',
        'This playlist is private.  To enable sharing, change the visibility setting within the Edit Playlist page.'
      );
    }
  );

  it(
    'Share playlist by link (set to "Share by link" under playlist details); then anyone should be able to view playlist - @Tc2ae4eb4',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.get('#playlists_nav').contains('Playlists').click();

      // Search and open playlist
      cy.get('#Playlists_filter').within(() => {
        cy.get('input[type="search"]').type(playlist_title);
      });
      cy.contains(playlist_title).click();

      // Go to edit playlist visibility
      cy.get('[data-testid="playlist-edit-playlist-btn"]')
        .should('be.visible')
        .click();
      cy.get('[data-testid="playlist-edit-icon-btn"]').click();

      // Set visibility to "Share by link"
      cy.get('input[type="radio"][value="private-with-token"]').check({
        force: true,
      });
      cy.get('input[type="radio"][value="private-with-token"]').should(
        'be.checked'
      );

      // Intercept and save
      cy.intercept('POST', '**/playlists/*').as('updatePlaylist');
      cy.get('[data-testid="playlist-submit-form"]')
        .contains('Save Changes')
        .click();

      cy.wait('@updatePlaylist').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
        expect(interception.response.headers.location).to.include('/edit');
      });

      // Validate share link
      cy.get('[data-testid="playlist-share-link"]')
        .should('be.visible')
        .and('have.attr', 'readonly');

      cy.get('[data-testid="playlist-share-link"]')
        .invoke('val')
        .should('include', '?token=');

      // Confirm copy button
      cy.get('[data-testid="playlist-copy-share-link-button"]').should(
        'contain.text',
        'Copy'
      );

      // View playlist and open share menu again (for link re-check, optional)
      cy.get('[data-testid="playlist-view-playlist-btn"]').click();
      cy.get('[data-testid="playlist-share-btn"]').click();

      //Saving the share link
      cy.get('[data-testid="playlist-link"]')
        .invoke('val')
        .should('include', '?token=')
        .as('playlistLink');

      // Logout admin
      homePage.logout();

      // Validate access as manager
      cy.login('manager');
      cy.get('@playlistLink').then((link) => {
        share_by_link_playlist = link;
        cy.visit(link);
        cy.get('[data-testid="playlist-title"]').should(
          'contain.text',
          playlist_title
        );
        cy.get('[data-testid="playlist-visibility-icon"]')
          .should('exist')
          .and(
            'have.attr',
            'title',
            'This playlist can only be viewed by users who have the unique link.'
          );
      });
      homePage.logout();

      // Validate access as regular user
      cy.login('user');
      cy.get('@playlistLink').then((link) => {
        cy.visit(link);
        cy.get('[data-testid="playlist-title"]').should(
          'contain.text',
          playlist_title
        );
        cy.get('[data-testid="playlist-visibility-icon"]')
          .should('exist')
          .and(
            'have.attr',
            'title',
            'This playlist can only be viewed by users who have the unique link.'
          );
      });
      homePage.logout();

      // Validate access as unauthenticated guest
      cy.get('@playlistLink').then((link) => {
        cy.visit(link);
        cy.get('[data-testid="playlist-title"]').should(
          'contain.text',
          playlist_title
        );
        cy.get('[data-testid="playlist-visibility-icon"]')
          .should('exist')
          .and(
            'have.attr',
            'title',
            'This playlist can only be viewed by users who have the unique link.'
          );
      });
    }
  );
  it(
    'Accessing a playlist with inaccessible items - @T5a36ed2c',
    { tags: '@high' },
    () => {
      // Logging in as user and item added to playlist is collection staff only
      cy.login('user');

      cy.visit(share_by_link_playlist);

      // Check that all playlist items have a lock icon
      cy.get('[data-testid="tree-item"]').each(($item) => {
        cy.wrap($item).find('svg.structure-item-locked').should('exist');
      });

      cy.get('[data-testid="tree-item"]').first().click();
      cy.get('[data-testid="media-player"]').should('exist');
      cy.get('[data-testid="inaccessible-message-display"]').should('exist');
      cy.get('[data-testid="inaccessible-message-content"]').should(
        'contain.text',
        'You do not have permission to playback this item.'
      );
      // Validate Next button and timer (first item only)
      cy.get('[data-testid="inaccessible-message-buttons"]')
        .find('[data-testid="inaccessible-next-button"]')
        .should('contain.text', 'Next')
        .and('be.visible');

      cy.get('[data-testid="inaccessible-message-timer"]')
        .should('contain.text', 'Next item in')
        .and('be.visible');

      // Click Next to go to second item
      cy.get('[data-testid="inaccessible-next-button"]').click();

      // Wait for transition (adjust if necessary)
      cy.wait(1000);

      // Validate timer and both nav buttons
      cy.get('[data-testid="inaccessible-message-buttons"]')
        .should('contain.text', 'Next')
        .and('contain.text', 'Previous');

      cy.get('[data-testid="inaccessible-message-timer"]').should(
        'contain.text',
        'Next item in'
      );

      // Click Next again to go to third item
      cy.get('[data-testid="inaccessible-next-button"]').click();
      cy.wait(1000);

      // Validate still both nav buttons present
      cy.get('[data-testid="inaccessible-message-buttons"]')
        .should('contain.text', 'Next')
        .and('contain.text', 'Previous');

      // Click Next again to go to fourth item
      cy.get('[data-testid="inaccessible-next-button"]').click();
      cy.wait(1000);

      // Validate both buttons again
      cy.get('[data-testid="inaccessible-message-buttons"]')
        .should('contain.text', 'Next')
        .and('contain.text', 'Previous');

      // Click Next to go to last item
      cy.get('[data-testid="inaccessible-next-button"]').click();
      cy.wait(1000);

      // Final item: should only show "Previous", no timer
      cy.get('[data-testid="inaccessible-message-buttons"]')
        .should('contain.text', 'Previous')
        .and('not.contain.text', 'Next');

      cy.get('[data-testid="inaccessible-message-timer"]').should('not.exist');

      // Validate that there are no markers
      cy.contains('button', 'Markers').click();
      cy.get('[data-testid="annotations-display"]').should('be.empty');
    }
  );

  it('Verify deleting items in the playlist', { tags: '@critical' }, () => {
    cy.login('administrator');
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
});
