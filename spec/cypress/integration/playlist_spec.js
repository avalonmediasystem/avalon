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

context('Playlists', () => {
  //Playlist names start with '_' character for easy navigation without pagination
  // var playlist_title = `_Automation playlist title ${Math.floor(Math.random() * 10000) + 1
  // 	}`;
  var playlist_title = '_Automation playlist title 2086';
  var playlist_description = `${playlist_title} description`;
  var playlist_title_public = `_Automation public playlist title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var playlist_description_public = `${playlist_title_public} description`;
  const media_object_id = Cypress.env('MEDIA_OBJECT_ID');
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
  });


  //is able to create a new playlist
  it('Verify creating a Playlist - @Tf1b9413d', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.get('#playlists_nav').contains("Playlists").click(); // present in mco-staging as well
    cy.get("[data-testid='createNewPlaylists']").contains("Create New Playlist").click();
    cy.get("[data-testid='playlistTitle']").type(playlist_title);
    cy.get("[data-testid='playlistComment']").type(playlist_description);
    cy.get("[data-testid='submitPlaylistForm']").click();

    //Validate play list creation success message
    cy.get("[data-testid='alert']")
      .should('be.visible')
      .within(() => {
        cy.get('p').should('contain', 'Playlist was successfully created.');
      });

    //Validate the newly created playlist page
    // Validate the presence of the video.js element
    cy.get('video[data-testid="videojs-audio-element"]')
      .should('exist')
      
      // .and('have.class', 'video-js')
      // .and('have.class', 'vjs-big-play-centered');
      //why were they added
    // Validate the presence of the text "This playlist currently has no playable items."
    cy.get('[data-testid="inaccessible-message-display"]')
      .should('be.visible')
      .within(() => {
        cy.get('[data-testid="inaccessible-message-content"]').should('contain.text', 'This playlist currently has no playable items.');
      });
      
    //validate the playlist details - title, description, buttons , etc
    cy.get('[data-testid="playlistTitle"]').get('h1').contains(playlist_title);
    //verify that the  playlist created by default is private
    cy.get('[data-testid="visibilityIcon"]')
    .should('be.visible')
    .and('have.attr', 'title', 'This playlist can only be viewed by you.');  
    cy.get('[data-testid="rampPlaylistDescription"]')
      .contains(playlist_description);
    cy.get('[data-testid="copyPlaylist"]').should('be.visible');
    cy.get('[data-testid="auto-advance"]').should('be.visible');
    cy.get('[data-testid="shareButton"]').should('be.visible');
    cy.get('[data-testid="editPlaylistButton"]').should('be.visible');
  });

  it('.validate_playlist_table()', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.get('#playlists_nav').contains("Playlists").click(); 
    cy.get('[ data-testid="playlistRow"]').should('be.visible').within(() => {
      cy.contains('Name').should('be.visible');
      cy.contains('Size').should('be.visible');
      cy.contains('Visibility').should('be.visible');
      cy.contains('Created').should('be.visible');
      cy.contains('Updated').should('be.visible');
      cy.contains('Tags').should('be.visible');
      cy.contains('Actions').should('be.visible');
    });

    cy.get('[data-testid="playlistTableBody"] tr')
    .contains('td', 'Testing Playlists')  
    .closest('tr')  
    .within(() => {
      cy.get('td').eq(2).should('contain.text', 'Private');  // Check visibility (Private)
      cy.get('td').eq(6).should('contain.text', 'Copy');
      cy.get('td').eq(6).should('contain.text', 'Edit');
      cy.get('td').eq(6).should('contain.text', 'Delete');
    });
  });

  // is able to create public playlist
  it('.create_public_playlist()', () => {
    cy.login('administrator');
    cy.visit('/');

    cy.get('#playlists_nav').contains("Playlists").click(); // present in mco-staging as well
    cy.get("[data-testid='createNewPlaylists']").contains("Create New Playlist").click();
    cy.get("[data-testid='playlistTitle']").type(playlist_title_public);
    cy.get("[data-testid='playlistComment']").type(playlist_description_public);   
    cy.contains('Public').click();
    cy.get("[data-testid='submitPlaylistForm']").click();
    
    cy.contains(playlist_title_public);
    cy.contains('Public');

    cy.get('[data-testid="visibilityIcon"]')
    .should('be.visible')
    .and('have.attr', 'title', 'This playlist can be viewed by anyone on the web.');
  });

  //is able to share a public playlist
  it('Verify sharing a public playlist - @c89c89d0', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.get('#playlists_nav').contains("Playlists").click();
    cy.contains(playlist_title_public).click();
    cy.get('[data-testid="shareButton"]').click();
    cy.get('[data-testid="shareList"]').within(() => {
      cy.url().then((currentUrl) => {
        cy.get('[ data-testid="publicLink"]').should('have.value', currentUrl);
      });
    });
  });

  // is able to change public playlist to private
  it('Verify editing a playlist from playlist table (Access control) - @T7fa4cea5', () => {
    cy.login('administrator');
    cy.visit('/');

    cy.get('#playlists_nav').contains("Playlists").click();
    cy.contains(playlist_title_public).click();
    cy.get('[data-testid="editPlaylistButton"]')
      .should('be.visible')
      .click();
    cy.get('[data-testid="playlistEditButton"]').click();
    cy.contains('Private').click();
    cy.contains('Save Changes').click();
    cy.get('[data-testid="alert"]').contains('Playlist was successfully updated');
    cy.contains('Private');
  });

  // is able to edit playlist name and description
  it('Verify editing a Playlist from playlist page - @T5055855c', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.get('#playlists_nav').contains("Playlists").click();
    cy.contains(playlist_title_public).click();
    cy.get('[data-testid="editPlaylistButton"]')
      .should('be.visible')
      .click();
    cy.get('[data-testid="playlistEditButton"]').click();

    var updated_title = '_Edited' + playlist_title_public;
    var updatedDescription = '_Edited' + playlist_description_public;

    cy.get('[data-testid="playlistTitle"]').clear().type(updated_title);
    cy.get('[data-testid="playlistComment"]').clear().type(updatedDescription);
    cy.get('[data-testid="submitPlaylistForm"]').contains('Save Changes').click();
    cy.get('[data-testid="alert"]').contains('Playlist was successfully updated');
    cy.get('[data-testid="playlistDetails"]')
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
  });

  it('Verify the "add to playlist" button behavior - @Tcdb5ac47', () => {
    cy.login('administrator');
    cy.visit('/');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.visit('/media_objects/' + media_object_id);
    cy.contains(media_object_title); 
    cy.get('[data-testid="addToPlaylistButton"]').contains('Add to Playlist').click();
    //Validate the "Add to playlist options"
    cy.get('[ data-testid="addToPlaylistForm"]').within(() => {
      cy.get('[data-testid="currentTrackRadioBtn"]').should('exist').parent().should('contain.text', 'Current Track (');
      cy.get('[ data-testid="customTimespanRadioBtn"]').should('exist').parent().should('contain.text', 'Custom Timespan');
      cy.get('[data-testid="currentSectionkRadioBtn"]').should('exist').parent().should('contain.text', 'Current Section (');
      cy.get('[data-testid="allSectionRadioBtn"]').should('exist').parent().should('contain.text', 'All Sections');
    });

    //Validate Playlist dropdown
    cy.get('[data-testid="playlistDropdown"]').next('span').click();

    //Validate add new playlist option in the dropdown
    cy.get('[data-testid="playlistSearchInput"]').parent().next() 
      .contains('Add new playlist').should('be.visible');
    
    //Validate search for playlist within the playlist dropdown
    cy.get('[data-testid="playlistSearchInput"]').type(playlist_title);
    cy.get('[data-testid="playlistSearchInput"]').parent().next() 
    .contains('b', playlist_title).should('be.visible');

  });

  it('Verify adding the current section of an item to a playlist - Create playlist items for each track/subsection - @T3e614dbc', () => {
    cy.login('administrator');
    cy.visit('/');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.visit('/media_objects/' + media_object_id);
    cy.contains(media_object_title);
    cy.get('[data-testid="addToPlaylistButton"]').contains('Add to Playlist').click();

    //Click on the "Current section" radio button
    cy.get('[data-testid="currentTrackRadioBtn"]').should('exist').parent().should('contain.text', 'Current Track (');

    //Open Playlist dropdown
    cy.get('[data-testid="playlistDropdown"]').next('span').click();

    //Validate search for playlist within the playlist dropdown
    cy.get('[data-testid="playlistSearchInput"]').type(playlist_title);
    cy.get('[data-testid="playlistSearchInput"]')
      .parent() 
      .next() 
      .find('b')
      .each(($el) => {
        
        const text = $el.text().trim();
        if (text === playlist_title) {
          cy.wrap($el).click(); 
        }
      });
    cy.get('[data-testid="addToPlaylistSave"]').click();

    //verify playlist created success message
    cy.get('[data-testid="addToPlaylistResultMsg"]')
      .should('be.visible')
      .contains('Add to playlist was successful.');
    cy.screenshot();
  });

  // Teardown codes  to delete playlist_title and playlist_title_public

  // deletes playlist permanently from playlists table
  //The "playlist_title" playlist gets deleted here
  it('Verify Deleting a Playlist - playlist table - @T53c3887a', () => {
    cy.login('administrator');
    cy.visit('/');

    cy.visit('/playlists');
    cy.get('[data-testid="playlistTableBody"] tr')
    .contains('td', playlist_title)  
    .closest('tr')  
    .within(() => {
      cy.get('[data-testid="deleteTableView"]').should('contain.text', 'Delete').click();
    });
    cy.contains('Yes, Delete').click();
    cy.get('[data-testid="alert"]').contains("Playlist was successfully destroyed.").should('be.visible');
    cy.visit('/playlists');

    //Add more assertions here
   //Handle pagination case - search for the playlist - it should not appear. Add  API validation
    
   cy.get('#Playlists_filter').within(()=>{
      cy.get('input[type="search"]').type(playlist_title);
    });
    cy.get('[data-testid="playlistTableBody"] tr').contains(playlist_title).should('not.exist');
  });

  // is able to delete playlist from edit playlist page
  //The "playlist_title_public" playlist gets deleted here
  it('Verify Deleting a Playlist - playlist page - @T49ac05b8', () => {
    cy.login('administrator');
    cy.visit('/');

    cy.visit('/playlists');
    cy.contains(playlist_title_public).click();
    cy.get('[data-testid="editPlaylistButton"]').click();

    cy.get('[data-testid="deletePlaylistForm"]').contains('Delete Playlist').click();
    cy.contains('Yes, Delete').click();
    cy.get('[data-testid="alert"]').contains("Playlist was successfully destroyed.").should('be.visible');
    cy.visit('/playlists');

    //Add more assertions here
    //Handle pagination case - search for the playlist - it should not appear. Add  API validation
    cy.get('#Playlists_filter').within(()=>{
      cy.get('input[type="search"]').type(playlist_title);
    });
    cy.get('[data-testid="playlistTableBody"] tr').contains(playlist_title).should('not.exist');

  });
});
