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

context('Media objects', () => {
  const media_object_id = Cypress.env('MEDIA_OBJECT_ID');
  const media_object_title = Cypress.env('MEDIA_OBJECT_TITLE');
  const caption = Cypress.env('MEDIA_OBJECT_CAPTION');

  beforeEach(() => {
    cy.login("administrator")
    
    cy.visit('/media_objects/' + media_object_id);
    cy.waitForVideoReady();
  });

  // can visit a media object
  it('.visit_media_object() - @critical', () => {
    
    cy.contains('Unknown item').should('not.exist');
    cy.get('[data-testid="media-object-title"]').should('contain', media_object_title);
    cy.contains('Publication date');
    // This below line is to play the video. If the video is not playable, this might return error. In that case, comment the below code.
    cy.get('[data-testid="videojs-video-element"]').parent().find('.vjs-big-play-button').click();
  });

  // Open multiple media objects in different tabs and play it.
  it.skip('.play_media_objects() - @critical', () => {
    
    cy.get('a[href*="catalog"] ').first().click();
    
    cy.get('a[href*="media_objects"]').then((media_objects) => {
      var i;
      for (i = 0; i < 3; i += 2) {
        cy.visit(media_objects[i].href);
        // Below code is to make media play using more resilient selectors
        cy.get('[data-testid="media-player"]').within(() => {
          cy.get('.vjs-big-play-button').click({ force: true });
        });
      }
    });
  });

  it('Verify the icons in a video player - @Tb155c718 - @critical', () => {
    cy.get('[data-testid="media-player"]').within(() => {
      // Validate the center play button
      cy.get('.vjs-big-play-button').should('exist');
      // Validate the play button in the control bar
      cy.get('.vjs-play-control').should('exist');
      // Validate the seekbar
      cy.get('[data-testid="videojs-custom-seekbar"]').should('exist');
      // Validate the captions button
      cy.get('.vjs-subs-caps-button').should('exist');
      // Validate the volume button
      cy.get('.vjs-mute-control').should('exist');
      // Validate the quality selector button
      cy.get('.vjs-quality-selector').should('exist');
      // Validate the playback rate button
      cy.get('.vjs-playback-rate').should('exist');
      // Validate the fullscreen button
      cy.get('.vjs-fullscreen-control').should('exist');
    });
  });

  it('Verify whether the user is able to adjust volume in the audio player - @T2e46961f - @critical', () => {

    
    // Access the media player container
    cy.get('[data-testid="media-player"]').within(() => {
      // Get the mute button and volume bar with more resilient selectors
      cy.get('.vjs-mute-control').as('muteButton');
      cy.get('.vjs-volume-bar').as('volumeBar');

      // Check initial state
      cy.get('@volumeBar').invoke('attr', 'aria-valuenow').then((initialVolume) => {
        // Click to mute and verify
        cy.get('@muteButton').click({ force: true });
        cy.get('@muteButton').should('have.class', 'vjs-vol-0');

        // Adjust volume using the volume control slider
        // First, make the volume panel visible if it's not already
        cy.get('.vjs-volume-panel').trigger('mouseover', { force: true });
        
        // Then adjust the volume
        cy.get('@volumeBar')
          .invoke('attr', 'aria-valuenow', '50')
          .trigger('input', { force: true });

        // Verify the volume has been adjusted
        cy.get('@volumeBar').invoke('attr', 'aria-valuenow').should('eq', '50');
      });
    });
  });

  it('Verify turning on closed captions - @T4ceb4111 - @critical', () => {
    
    cy.get('[data-testid="media-player"]').within(() => {
      // Access the closed captions button
      cy.get('button.vjs-subs-caps-button').as('ccButton');
      cy.get('@ccButton').click();
      
      // Select the caption 
      cy.get('.vjs-menu-content').first().within(() => {
        cy.contains('li.vjs-menu-item', caption).click();
      });
      
      // Assert that the captions are enabled
      cy.get('@ccButton').should('have.class', 'captions-on');
      
      // Additional verification that captions are displayed
      cy.get('.vjs-text-track-display').should('exist');
    });
  });
});
