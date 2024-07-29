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

context('Media objects', () => {
  const media_object_id = Cypress.env('MEDIA_OBJECT_ID_2');
  const media_object_title = Cypress.env('MEDIA_OBJECT_TITLE_2');
  const caption = Cypress.env('MEDIA_OBJECT_CAPTION_2');

  beforeEach(() => {
    cy.login("administrator")
    cy.visit('/media_objects/' + media_object_id);
  });

  // can visit a media object
  it('.visit_media_object()', () => {
    cy.login('administrator');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.visit('/media_objects/' + media_object_id);
    cy.contains('Unknown item').should('not.exist');
    cy.contains(media_object_title);
    cy.contains('Date');
    // This below line is to play the video. If the video is not playable, this might return error. In that case, comment the below code.
    cy.get('button[title="Play"]').click();
  });

  // Open multiple media objects in different tabs and play it.
  it.skip('.play_media_objects()', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.get('a[href*="catalog"] ').first().click();
    //cy.get(' a[href*="/media_objects/"] ').first().click()
    cy.get('a[href*="media_objects').then((media_objects) => {
      function printObject(o) {
        var out = '';
        for (var p in o) {
          out += p + ': ' + o[p] + '\n';
        }
        alert(out);
      }
      var i;
      for (i = 0; i < 3; i += 2) {
        //media_objects[i].click()
        //cy.get('div').should('have.class', 'mejs__overlay-play').first().click()
        window.open(media_objects[i]);
        cy.visit(String(media_objects[i]));
        // Below code is to make media play
        cy.window()
          .get('div')
          .should('have.class', 'mejs__overlay-play')
          .first()
          .click({ force: true });
      }
    });
  });

  it('Verify the icons in a video player - @Tb155c718', () => {
    cy.get('.vjs-big-play-button[title="Play Video"]').should('exist'); //validates the centre play button
    cy.get('.vjs-play-control[title="Play"]').should('exist'); //validates the  play button in the control bar
    cy.get('#slider-range'); //validates the slider
    cy.get('.vjs-subs-caps-button[title="Captions"]').should('exist'); //validates the captions button
    cy.get('.vjs-mute-control[title="Mute"]').should('exist'); //validates the Audio button
    cy.get('button[title="Open quality selector menu"]').should('exist'); //validates the quality selector button
    cy.get('button[title="Playback Rate"]').should('exist'); //validates the playback rate  button
    cy.get('button[title="Fullscreen"]').should('exist'); //validates the playback rate  button
  });

  it.only('Verify whether the user is able to adjust volume in the audio player - @T2e46961f', () => {
    // Assume the video player is already loaded and accessible
    cy.get('.vjs-mute-control').as('muteButton');
    cy.get('.vjs-volume-bar').as('volumeBar');

    // Check initial state if needed
    cy.get('@volumeBar').invoke('attr', 'aria-valuenow').should('eq', '100'); // Checking initial volume level, adjust as needed

    // Click to mute and verify
    cy.get('@muteButton').click();
    cy.get('@muteButton').should('have.class', 'vjs-vol-0'); // Checking if the mute button reflects the muted state

     // Adjust volume using the volume control slider
     cy.get('@volumeBar')
  .invoke('val', 50)
  .trigger('input', { force: true })
  .trigger('change', { force: true }); // Adjust the slider to a midpoint value

      // Verify the volume has been adjusted
    cy.get('@volumeBar').invoke('attr', 'aria-valuenow').should('eq', '50'); // Confirm the slider reflects the new volume level



  });

  it.only('Verify turning on closed captions - @T4ceb4111', () => {
    // Access the closed captions button
    cy.get('.vjs-subs-caps-button').as('ccButton');
    cy.get('@ccButton').click();
    // Select the caption
    cy.contains('li.vjs-subtitles-menu-item', caption).click();
    // Assert that the captions are enabled - the class name should change to captions-on
    cy.get('@ccButton').should('have.class', 'captions-on'); // Change 'captions-on' to the actual class or attribute that indicates active captions

    //Add more assertions here to verefy captions on the screen
  });
});
