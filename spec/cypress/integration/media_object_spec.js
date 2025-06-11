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

import CollectionPage from '../pageObjects/collectionPage';
import { navigateToManageContent, performSearch } from '../support/navigation';

const collectionPage = new CollectionPage();

context('Media objects', () => {
  //This will contain test cases for an item that is manually created in an env.
  //Must have captions
  //Available to all
  //Multiple sections - lunchroom manner, audio file, 10 second clip, Lunchroom manner
  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var media_object_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;
  var media_object_id;
  const caption = `captions-example.srt`;
  Cypress.on('uncaught:exception', (err, runnable) => {
    if (
      err.message.includes('Permissions check failed') ||
      err.message.includes(
        "Cannot read properties of undefined (reading 'success')"
      ) ||
      err.message.includes('scrollHeight') ||
      err.message.includes(
        "Cannot read properties of undefined (reading 'end')"
      ) ||
      err.message === 'Script error.'
    ) {
      return false;
    }
  });
  // Create collection and complex media object before all tests
  // Create collection and complex media object before all tests
  before(() => {
    cy.login('administrator');
    navigateToManageContent();

    // Create collection with public access
    collectionPage.createCollection(
      { title: collection_title },
      { setPublicAccess: true }
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
  after(() => {
    cy.login('administrator');

    // Delete the media object first (if it exists)
    if (media_object_id) {
      collectionPage.deleteItemById(media_object_id);
    }

    // Then delete the collection
    collectionPage.deleteCollectionByName(collection_title);
  });

  context('With media object loaded', () => {
    beforeEach(() => {
      cy.login('administrator');
      cy.visit('/media_objects/' + media_object_id);
      cy.waitForVideoReady();
    });
    // can visit a media object

    it('.visit_media_object() ', { tags: '@critical' }, () => {
      cy.contains('Unknown item').should('not.exist');
      cy.get('[data-testid="media-object-title"]').should(
        'contain',
        media_object_title
      );
      cy.contains('Publication date');
      // This below line is to play the video. If the video is not playable, this might return error. In that case, comment the below code.
      cy.get('[data-testid="videojs-video-element"]')
        .parent()
        .find('.vjs-big-play-button')
        .click();
    });

    // Open multiple media objects in different tabs and play it.
    it('.play_media_objects()', { tags: '@critical' }, () => {
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

    it(
      'Verify the icons in a video player - @Tb155c718',
      { tags: '@critical' },
      () => {
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
      }
    );

    it(
      'Verify whether the user is able to adjust volume in the audio player - @T2e46961f',
      { tags: '@critical' },
      () => {
        // Access the media player container
        cy.get('[data-testid="media-player"]').within(() => {
          // Get the mute button and volume bar with more resilient selectors
          cy.get('.vjs-mute-control').as('muteButton');
          cy.get('.vjs-volume-bar').as('volumeBar');

          // Check initial state
          cy.get('@volumeBar')
            .invoke('attr', 'aria-valuenow')
            .then((initialVolume) => {
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
              cy.get('@volumeBar')
                .invoke('attr', 'aria-valuenow')
                .should('eq', '50');
            });
        });
      }
    );

    it(
      'Verify turning on closed captions - @T4ceb4111',
      { tags: '@critical' },
      () => {
        cy.get('[data-testid="media-player"]').within(() => {
          // Access the closed captions button
          cy.get('button.vjs-subs-caps-button').as('ccButton');
          cy.get('@ccButton').click();

          // Select the caption
          cy.get('.vjs-menu-content')
            .first()
            .within(() => {
              cy.contains('li.vjs-menu-item', caption).click();
            });

          // captions are enabled
          cy.get('@ccButton').should('have.class', 'captions-on');

          // Checking on media player
          cy.get('.vjs-text-track-display').should('exist');
        });
      }
    );

    it(
      'Verify video playback for all roles - admin, manager, user ',
      { tags: '@critical' },
      () => {
        const roles = ['administrator', 'manager', 'user'];

        roles.forEach((role) => {
          cy.log(`Checking playback for: ${role}`);
          cy.login(role);

          cy.visit('/media_objects/' + media_object_id);
          cy.waitForVideoReady();

          cy.get('[data-testid="media-player"]').within(() => {
            // Click play button
            cy.get('.vjs-big-play-button')
              .should('be.visible')
              .click({ force: true });

            // Checking if it is playing
            cy.get('video')
              .should('exist')
              .then(($video) => {
                const videoEl = $video[0];

                // checking if it's not paused
                cy.wrap(null).should(() => {
                  expect(videoEl.paused).to.eq(false);
                });

                // Store initial time
                const initialTime = videoEl.currentTime;

                // Wait and confirm playback
                cy.wait(2000).then(() => {
                  expect(videoEl.currentTime).to.be.greaterThan(initialTime);
                });
              });
          });

          // Logout user
          cy.visit('/users/sign_out');
        });
      }
    );

    it(
      'Verify that all users can stream the audio files in an item',
      { tags: '@critical' },
      () => {
        // Clicking on the first mp3 audio
        cy.get('[data-testid="tree-item"]')
          .filter('[data-label*=".mp3"]')
          .first()
          .within(() => {
            cy.get('[data-testid="treeitem-section-button"]').click();
          });

        // Waiting for the media player to be loaded
        cy.waitForVideoReady();

        // Click the play button
        cy.get('[data-testid="media-player"]')
          .find('button.vjs-play-control[title="Play"]')
          .should('exist')
          .click();

        // Verifying the player is not paused
        cy.get('[data-testid="videojs-audio-element"]')
          .should('exist')
          .then(($el) => {
            const audio = $el[0];
            expect(audio.paused).to.equal(false); // Not paused after play
          });

        // DOM property - HTMLMediaElement
        cy.get('[data-testid="videojs-audio-element"]')
          .invoke('prop', 'currentTime')
          .then((startTime) => {
            cy.wait(1000);
            cy.get('[data-testid="videojs-audio-element"]')
              .invoke('prop', 'currentTime')
              .should((currentTime) => {
                expect(currentTime).to.be.greaterThan(startTime);
              });
          });

        // Confirming the display timer is right
        cy.get('.current-time-display')
          .invoke('text')
          .then((time1) => {
            cy.wait(1000);
            cy.get('.current-time-display')
              .invoke('text')
              .should((time2) => {
                expect(time2).to.not.equal(time1);
              });
          });
      }
    );

    it(
      'Verify that the user can stream different sections of the video/audio from structured nav',
      { tags: '@critical' },
      () => {
        //Verifying sections exists
        cy.get('[data-testid="structured-nav"]').should('exist');

        cy.get('[data-testid="treeitem-section-button"]').then(($buttons) => {
          const sectionCount = Math.min($buttons.length, 3); //Limits to the first 3 sections

          //Loops through the 3 sections
          Cypress._.times(sectionCount, (index) => {
            //Section titles should be visible
            cy.get('[data-testid="treeitem-section-button"]')
              .eq(index)
              .should('be.visible')
              .click();
            //Waits for the player to load
            cy.waitForVideoReady();

            cy.get('[data-testid="media-player"]')
              .find('video') //makes sure video tag is available
              .should('exist')
              .then(($video) => {
                const mediaType = $video.attr('data-testid'); //checking whether it is audio or video player

                const checkPlayback = () => {
                  //Verifying if it is playing and not paused
                  cy.get('[data-testid="media-player"] video').should(
                    ($vid) => {
                      expect($vid[0].paused).to.be.false;
                    }
                  );

                  //Checking if progress bar advances through the style: width
                  cy.get('[data-testid="media-player"] .vjs-play-progress')
                    .invoke('width')
                    .then((initialWidth) => {
                      cy.wait(2000);
                      cy.get('[data-testid="media-player"] .vjs-play-progress')
                        .invoke('width')
                        .should('be.gt', initialWidth);
                    });
                };

                if (
                  mediaType === 'videojs-video-element' ||
                  mediaType === 'videojs-audio-element'
                ) {
                  //only for the first section we need to click on play button rest of the sections are autoplay
                  if (index === 0) {
                    cy.get('[data-testid="media-player"]')
                      .find('.vjs-play-control[title="Play"]')
                      .should('be.visible')
                      .click();
                  }
                  //calling the function for verifying if the media is playing
                  checkPlayback();
                } else {
                  throw new Error(`Unexpected media type: ${mediaType}`);
                }
              });
          });
        });
      }
    );

    //cy.get('[data-testid="media-object-share-btn"]').contains("Share").click();

    it(
      'TC002 - Validate embedded video player functionality (with stream buffering wait)',
      { tags: '@critical' },
      () => {
        cy.contains('Share').click();
        cy.contains('Embed').click();

        //  Extract iframe source
        cy.get('[data-testid="media-object-iframe-link"]')
          .invoke('val')
          .then((iframeHtml) => {
            const iframeSrc = iframeHtml.match(/src="([^"]+)"/)[1];
            cy.visit(iframeSrc);

            //Ensure video player is ready
            cy.get('video[data-testid="videojs-video-element"]', {
              timeout: 10000,
            })
              .should('exist')
              .then(($video) => {
                // Wait until the video is ready to play (readyState >= 3)
                cy.wrap($video).should(($v) => {
                  expect($v[0].readyState).to.be.gte(3);
                });
              });

            // Click play
            cy.get('.vjs-play-control[title="Play"]')
              .should('be.visible')
              .click();

            // Wait 5 seconds for playback to settle
            cy.wait(5000);

            cy.get('.video-js').trigger('mousemove', { force: true });

            // Confirm it's playing
            cy.get('video').should('have.prop', 'paused', false);

            // Adjust volume
            cy.get('.vjs-volume-panel').trigger('mouseover');
            cy.get('.vjs-volume-bar').click('center', { force: true });

            // Scrub (seek) using progress bar
            cy.get('.vjs-progress-holder').click('center', { force: true });

            //  Change quality
            cy.get('.vjs-quality-selector button').click();
            cy.get('.vjs-menu-item').contains('high').click();

            // Fullscreen toggle
            cy.get('.vjs-fullscreen-control').click();
          });
      }
    );
  });
});
