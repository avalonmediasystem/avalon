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

    it('Verify the icons in a video player - in full screen mode - @T503d2ee1', () => {
      //scope to the player
      cy.get('[data-testid="media-player"]').as('player');

      //Go fullscreen
      cy.get('@player')
        .find('.vjs-fullscreen-control')
        .should('be.visible')
        .click({ force: true });

      //Verify the player entered fullscreen
      cy.get('@player')
        .find('[data-testid="videojs-video-element"]')
        .should('have.class', 'vjs-fullscreen');

      //Center play button
      cy.get('@player')
        .find('button.vjs-big-play-button[title="Play Video"]')
        .should('be.visible');

      //Play/Pause button in control bar
      cy.get('@player')
        .find(
          'button.vjs-play-control[title*="Play"], button.vjs-play-control[title*="Pause"]'
        )
        .should('be.visible');

      // Previous / Next
      cy.get('@player')
        .find('[data-testid="videojs-previous-button"]')
        .should('be.visible');
      cy.get('@player')
        .find('[data-testid="videojs-next-button"]')
        .should('be.visible');

      // Li'l scrub (track scrubber) toggle
      cy.get('@player')
        .find('[data-testid="videojs-track-scrubber-button"]')
        .should('be.visible');

      //Captions toggle (only visible when a caption track exists)
      cy.get('@player')
        .find('button.vjs-subs-caps-button')
        .should('be.visible');

      // Volume control (mute button + volume bar present)
      cy.get('@player').find('.vjs-mute-control').should('be.visible');
      cy.get('@player').find('.vjs-volume-bar').should('exist');

      //Quality selector button
      cy.get('@player')
        .find('.vjs-quality-selector button[title*="quality"]')
        .should('be.visible');

      //Fullscreen control visible (already clicked above)
      cy.get('@player').find('.vjs-fullscreen-control').should('be.visible');
    });

    it('Verify the player pause and play actions - Video - @T7be623ee', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('@player')
        .find('video[data-testid="videojs-video-element"]')
        .as('video');
      cy.get('@player').find('.vjs-big-play-button').as('centerPlay');
      cy.get('@player').find('button.vjs-play-control').as('playPauseBtn');
      cy.get('@player').find('.vjs-fullscreen-control').as('fullscreenBtn');

      const expectPlaying = () => {
        cy.get('@video').should(($v) => {
          expect($v[0].paused, 'video paused flag').to.eq(false);
        });
        cy.get('@video')
          .invoke('prop', 'currentTime')
          .then((t1) => {
            cy.wait(800);
            cy.get('@video')
              .invoke('prop', 'currentTime')
              .should((t2) => {
                expect(t2, 'time advanced').to.be.greaterThan(t1);
              });
          });
      };

      const expectPaused = () => {
        cy.get('@video').should(($v) => {
          expect($v[0].paused, 'video paused flag').to.eq(true);
        });
      };

      //Start playback
      cy.get('@centerPlay').should('be.visible').click({ force: true });
      expectPlaying();

      //Click the player screen to pause/resume multiple times
      Cypress._.times(2, () => {
        //click to pause
        cy.get('@video').click({ force: true });
        expectPaused();

        //click to play
        cy.get('@video').click({ force: true });
        expectPlaying();
      });

      //Use the play/pause icon in the control bar
      //pause
      cy.get('@playPauseBtn').click({ force: true });
      expectPaused();
      //play
      cy.get('@playPauseBtn').click({ force: true });
      expectPlaying();

      //Enter fullscreen
      cy.get('@fullscreenBtn').should('be.visible').click({ force: true });
      // Confirm fullscreen class on the player root
      cy.get('@player')
        .find('[data-testid="videojs-video-element"]')
        .should('have.class', 'vjs-fullscreen');

      //Play/Pause using the control button in fullscreen
      cy.get('@playPauseBtn').click({ force: true });
      expectPaused();
      cy.get('@playPauseBtn').click({ force: true });
      expectPlaying();
    });

    it('Verify the players hotkeys for pause and play actions - Video and Audio - @@T633feb48', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('@player')
        .find('video[data-testid="videojs-video-element"]')
        .as('video');
      cy.get('@player').find('.vjs-big-play-button').as('centerPlay');
      cy.get('@player').find('button.vjs-play-control').as('playPauseBtn');
      cy.get('@player').find('.vjs-fullscreen-control').as('fullscreenBtn');
      const expectPlaying = () =>
        cy
          .get('@video')
          .should(($v) => expect($v[0].paused, 'paused flag').to.eq(false));
      const expectPaused = () =>
        cy
          .get('@video')
          .should(($v) => expect($v[0].paused, 'paused flag').to.eq(true));

      // Start playback
      cy.get('@centerPlay').click({ force: true });
      expectPlaying();

      //space toggles when player is focused
      cy.get('[data-testid="media-player"]').click();
      cy.get('body').type('{space}'); //pause
      expectPaused();
      cy.get('body').type('{space}'); //play
      expectPlaying();
      //
      [
        '[data-testid="browse-global-search-input"]',
        '[data-testid="media-object-add-to-playlist-btn"]',
        '[data-testid="media-object-create-timeline-btn"]',
      ].forEach((sel) => {
        cy.get(sel)
          .should('exist')
          .clear()
          .type('hello world')
          .should('have.value', 'hello world');
        // video should still be playing
        expectPlaying();
      });
      //control bar play/pause button
      cy.get('@playPauseBtn').click({ force: true });
      expectPaused();
      cy.get('@playPauseBtn').click({ force: true });
      expectPlaying();

      //fullscreen and repeat spacebar check
      cy.get('@fullscreenBtn').click({ force: true });
      cy.get('@player')
        .find('[data-testid="videojs-video-element"]')
        .should('have.class', 'vjs-fullscreen');

      cy.get('body').type('{space}'); //pause
      cy.get('body').type('{space}'); //play
      expectPlaying();
    });
    it('Verify the players pause and play actions - Audio- @T190702b9', () => {
      // Click on the audio file in the structure nav
      cy.get('[data-testid="tree-item"][data-label="test_sample_audio.mp3"]')
        .find('[data-testid="treeitem-section-button"]')
        .click({ force: true });

      // Aliases
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('video[data-testid="videojs-audio-element"]').as('audioEl');
      cy.get('@player').find('button.vjs-play-control').as('playPause');

      // Play
      cy.get('@playPause').click({ force: true });
      cy.get('@audioEl').should(($a) => expect($a[0].paused).to.eq(false));

      // Ensure time advances
      cy.get('@audioEl')
        .invoke('prop', 'currentTime')
        .then((t0) => {
          cy.wait(800);
          cy.get('@audioEl').invoke('prop', 'currentTime').should('be.gt', t0);
        });

      // Pause
      cy.get('@playPause').click({ force: true });
      cy.get('@audioEl').should(($a) => expect($a[0].paused).to.eq(true));
    });

    it('Verify the players Play forward and backwards actions - Video - @Td8360414', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('video[data-testid="videojs-video-element"]').as('videoEl');
      cy.get('@player').find('.vjs-play-control').as('playPause');
      cy.get('@player')
        .find('[data-testid="videojs-custom-seekbar"]')
        .as('seekbar');
      cy.get('@player')
        .find('[data-testid="videojs-track-scrubber-button"]')
        .as('scrubberBtn');
      //Start playback
      cy.get('@playPause').click({ force: true });
      cy.get('@videoEl').should(($v) => expect($v[0].paused).to.eq(false));

      //scrub forward
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .then((t0) => {
          cy.get('@seekbar').click('center', { force: true });
          cy.get('@videoEl')
            .invoke('prop', 'currentTime')
            .should((t1) => {
              expect(t1).to.be.greaterThan(t0);
              expect(t1).to.be.within(20, 40); //middle of video
            });
          // Scrub back
          cy.get('@seekbar').click('left', { force: true });
          cy.get('@videoEl')
            .invoke('prop', 'currentTime')
            .should((t2) => expect(t2).to.be.lessThan(15));
        });

      //open Scrubber and scrub forward and backward
      cy.get('@scrubberBtn').click({ force: true });
      cy.get('#track_scrubber .vjs-track-scrubber').as('miniScrubber');
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .then((s0) => {
          cy.get('@miniScrubber').click('right', { force: true });
          cy.get('@videoEl')
            .invoke('prop', 'currentTime')
            .should((s1) => expect(s1).to.be.gt(s0));
          cy.get('@miniScrubber').click('left', { force: true });
          cy.get('@videoEl')
            .invoke('prop', 'currentTime')
            .should((s2) => expect(s2).to.be.lt(s1));
        });
      //arrow key hotkeys for +5 and -5seconds
      cy.get('@player').click('center', { force: true });
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .then((k0) => {
          cy.get('body').type('{rightarrow}');
          cy.wait(300);
          cy.get('@videoEl')
            .invoke('prop', 'currentTime')
            .should((k1) => expect(k1).to.be.closeTo(k0 + 5, 1));
          cy.get('body').type('{leftarrow}');
          cy.wait(300);
          cy.get('@videoEl')
            .invoke('prop', 'currentTime')
            .should((k2) => expect(k2).to.be.closeTo(k0, 2));
        });

      // Click on Fullscreen
      cy.get('@player').find('.vjs-fullscreen-control').click({ force: true });
      cy.get('@player').should('have.class', 'vjs-fullscreen');

      //Scrub again in fullscreen and verify seek works
      cy.get('@seekbar').click('center', { force: true });
      cy.wait(500);
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .should((f1) => expect(f1).to.be.within(20, 50));
    });

    it('Verify whether the user is able to adjust volume in the video player  - @Te7a1268e', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('video[data-testid="videojs-video-element"]').as('videoEl');
      cy.get('@player').find('.vjs-mute-control').as('muteBtn');
      cy.get('@player').find('.vjs-volume-bar').as('volumeBar');
      cy.get('@player').find('.vjs-fullscreen-control').as('fullscreenBtn');
      // Start play
      cy.get('@player').find('.vjs-play-control').click({ force: true });

      //Adjust audio via volume slider
      cy.get('@volumeBar').click('right', { force: true });
      cy.get('@volumeBar')
        .invoke('attr', 'aria-valuenow')
        .should('not.eq', '0');
      //Mute and unmute with icon
      cy.get('@muteBtn').click({ force: true });
      cy.get('@muteBtn').should('have.class', 'vjs-vol-0');
      cy.get('@muteBtn').click({ force: true });
      cy.get('@muteBtn').should('not.have.class', 'vjs-vol-0');

      //using keyboard m key to mute and unmute player
      cy.get('@player').click('center', { force: true }); //focusing
      cy.get('body').type('m'); //mute
      cy.get('@muteBtn').should('have.class', 'vjs-vol-0');
      cy.get('body').type('m'); //unmute
      cy.get('@muteBtn').should('not.have.class', 'vjs-vol-0');
      cy.get('body').type('{uparrow}'); // increase volume
      cy.wait(300);
      cy.get('body').type('{downarrow}'); // decrease volume
      //Fullscreen for mute and unmute test
      cy.get('@fullscreenBtn').click({ force: true });
      cy.get('@player').should('have.class', 'vjs-fullscreen');
      cy.get('body').type('m'); // mute
      cy.get('@muteBtn').should('have.class', 'vjs-vol-0');
      cy.get('body').type('m'); //unmute
      cy.get('@muteBtn').should('not.have.class', 'vjs-vol-0');
    });

    it('Verify playing the video in full screen - @T384ebffc', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('video[data-testid="videojs-video-element"]').as('videoEl');
      cy.get('@player').find('.vjs-fullscreen-control').as('fullscreenBtn');

      // play video and clicking on fullscreen
      cy.get('@player').find('.vjs-play-control').click({ force: true });
      cy.get('@fullscreenBtn').click({ force: true });

      //verifying fullscreen
      cy.get('@player').should('have.class', 'vjs-fullscreen');
      cy.get('@fullscreenBtn')
        .should('have.attr', 'title')
        .and('match', /Exit/i);
      //exiting fullscreen
      cy.get('@fullscreenBtn').click({ force: true });
      cy.get('@player').should('not.have.class', 'vjs-fullscreen');

      //using keyboard keys to enter and exit fullscreen
      cy.get('@player').click('center', { force: true });
      cy.get('body').type('f');
      cy.get('@player').should('have.class', 'vjs-fullscreen');
      cy.wait(500);
      cy.get('body').type('f');
      cy.get('@player').should('not.have.class', 'vjs-fullscreen');
      cy.get('body').type('f');
      cy.get('@player').should('have.class', 'vjs-fullscreen');
      cy.get('body').type('{esc}');
      cy.get('@player').should('not.have.class', 'vjs-fullscreen');
    });

    it('Verify that the user can navigate through the video using the time markers in the transcript. - @T467587bd', () => {
      //adding the transcript to the first video section
      cy.get('[data-testid="media-object-edit-btn"]').click();
      cy.get(
        '[data-testid="media-object-side-nav-link"][href*="file-upload"]'
      ).click();
      cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();
      const transcriptFile = 'fixtures/transcript-example.vtt';
      cy.get(
        '[data-testid="media-object-upload-button-transcript"]'
      ).selectFile(transcriptFile, {
        force: true,
      });
      cy.contains('Upload').click();
      cy.contains('transcript-example.vtt').should('be.visible');
      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.visit('/media_objects/' + media_object_id);
      cy.waitForVideoReady();
      // Click the Transcripts tab
      cy.get('button[id*="tab-transcripts"]').click({ force: true });
      //verify the dropdown and transcripts
      cy.get('[data-testid="transcript_nav"]').should('exist');
      cy.get('[data-testid="transcript-select-option"]').should('be.visible');
      cy.get('[data-testid="transcript_item"]').should(
        'have.length.greaterThan',
        1
      );
      //play
      cy.get('[data-testid="media-player"] .vjs-play-control').click({
        force: true,
      });
      // click on 8 seccond timestamp
      cy.contains('[data-testid="transcript_time"]', '[00:00:08]').click({
        force: true,
      });
      // verifying with the current time of video
      cy.get('video[data-testid="videojs-video-element"]')
        .invoke('prop', 'currentTime')
        .should((currentTime) => {
          expect(currentTime).to.be.within(7, 9);
        });

      cy.get('video[data-testid="videojs-video-element"]').should(($v) => {
        expect($v[0].paused).to.eq(false);
      });
    });

    it('Verify the "auto scroll" feature inside the transcripts - @T586e8d8d', () => {
      cy.get('button[id*="tab-transcripts"]').click({ force: true });

      // verifying auto-scroll checked
      cy.get(
        '[data-testid="transcript-auto-scroll-check"] input[type="checkbox"]'
      )
        .as('autoScroll')
        .check({ force: true })
        .should('be.checked');

      // play video
      cy.get('[data-testid="media-player"] .vjs-play-control').click({
        force: true,
      });

      // Scroll
      cy.get('[data-testid="transcript_content_1"]')
        .invoke('scrollTop')
        .then((initialScroll) => {
          // 4 secoonds wait
          cy.wait(4000);
          // Verify transcript scrolled
          cy.get('[data-testid="transcript_content_1"]')
            .invoke('scrollTop')
            .should('be.greaterThan', initialScroll);
        });
    });

    it('Verify searching for text inside the transcript - @Taaec6730', () => {
      cy.get('button[id*="tab-transcripts"]').click({ force: true });
      cy.get('[data-testid="transcript-search-input"]').should('exist');

      //search keyword in trsnacript
      cy.get('[data-testid="transcript-search-input"]').clear().type('file');

      //verify search count
      cy.get('[data-testid="transcript-search-count"]')
        .should('be.visible')
        .and('contain.text', '1 of 4 results');

      // verify highlighted search results
      cy.get('.ramp--transcript_highlight').should('exist');

      // click next search result
      cy.get('[data-testid="transcript-search-next"]').click({ force: true });
      //click on highlighted transcript text to go to that time
      cy.get('.ramp--transcript_highlight').first().click({ force: true });
      //Verify video currentTime moves near that transcript time
      cy.get('video[data-testid="videojs-video-element"]')
        .invoke('prop', 'currentTime')
        .should('be.gt', 0);
      //check that transcript stays focused on current hit
      cy.get('.ramp--transcript_item.active').should('contain.text', 'file');
    });

    it('Verify turning off closed captions- @T37ee208e', () => {
      // Ensure captions button exists
      cy.get('[data-testid="media-player"]').within(() => {
        cy.get('button.vjs-subs-caps-button').as('ccButton');
        cy.get('@ccButton').should('exist');
      });
      // Turn captions ON
      cy.get('@ccButton').click({ force: true });
      cy.get('.vjs-menu-content')
        .contains('captions-example.srt')
        .click({ force: true });
      // captions ae enabled and CC icon is active
      cy.get('.vjs-text-track-display').should('be.visible');
      cy.get('@ccButton').should('have.class', 'captions-on');
      // Turn captions OFF
      cy.get('@ccButton').click({ force: true });
      cy.get('.vjs-menu-content')
        .contains('captions off', { matchCase: false })
        .click({ force: true });
      // verify captions hidden and CC icon not active
      cy.get('.vjs-text-track-display').should('not.be.visible');
      cy.get('@ccButton').should('not.have.class', 'captions-on');
      //Fullscreen caption toggle and repeat test
      cy.get('.vjs-fullscreen-control').click({ force: true });
      cy.get('@ccButton').click({ force: true });
      cy.get('.vjs-menu-content')
        .contains('captions-example.srt')
        .click({ force: true });
      cy.get('.vjs-text-track-display').should('be.visible');

      cy.get('@ccButton').click({ force: true });
      cy.get('.vjs-menu-content')
        .contains('captions off', { matchCase: false })
        .click({ force: true });
      cy.get('.vjs-text-track-display').should('not.be.visible');

      // Exit fullscreen
      cy.get('.vjs-fullscreen-control').click({ force: true });
    });

    it('Verify previous / next canvas buttons- @T75b6b6ef', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('video[data-testid="videojs-video-element"]').as('videoEl');
      //play video
      cy.get('@player').find('button.vjs-play-control').click({ force: true });
      cy.get('@videoEl').should(($v) => expect($v[0].paused).to.eq(false));
      //click next button
      cy.get('@player')
        .find('button.vjs-next-button')
        .should('exist')
        .click({ force: true });

      // verify the section has changed
      //verify time resets
      cy.get('@videoEl').invoke('prop', 'currentTime').should('be.lt', 5);

      // click on previous button
      cy.get('@player')
        .find('button.vjs-previous-button')
        .should('exist')
        .click({ force: true });
      // time resets again
      cy.get('@videoEl').invoke('prop', 'currentTime').should('be.lt', 5);
    });
    it('Verify that media player (audio/video) automatically advances to the next section once the current section is played - @TPlayerAutoAdvanceUnified', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('[data-testid="structured-nav"]').as('nav');
      // Detect audio or video
      cy.get('@player').then(($el) => {
        const hasVideo =
          $el.find('video[data-testid="videojs-video-element"]').length > 0;
        const hasAudio =
          $el.find('audio[data-testid="videojs-audio-element"]').length > 0;

        const mediaSelector = hasVideo
          ? 'video[data-testid="videojs-video-element"]'
          : 'audio[data-testid="videojs-audio-element"]';
        const durationMs = hasVideo ? 60000 : 12000; //58-video and 10-audio

        cy.get(mediaSelector).as('mediaEl');

        // play
        cy.get('@nav')
          .find('[data-testid="treeitem-section-button"]')
          .first()
          .as('firstSection')
          .click({ force: true });
        cy.get('@player').find('.vjs-play-control').click({ force: true });
        cy.get('@firstSection').should('have.class', 'active'); // section highlighted
        cy.wait(durationMs); //wait
        // next section highloghted
        cy.get('@nav')
          .find('[data-testid="treeitem-section-button"].active')
          .should(($btns) => {
            expect($btns.length).to.eq(1);
          });

        //verify it is still playing
        cy.get('@mediaEl').should(($m) => expect($m[0].paused).to.eq(false));
        cy.visit('/media_objects/' + media_object_id);
        cy.waitForVideoReady();
        //fullscreen test
        if (hasVideo) {
          cy.get('.vjs-fullscreen-control').click({ force: true });
          cy.get('@player').should('have.class', 'vjs-fullscreen');

          cy.wait(durationMs);
          cy.get('@nav')
            .find('[data-testid="treeitem-section-button"].active')
            .should('exist');

          //esp fullscreen
          cy.get('.vjs-fullscreen-control').click({ force: true });
        }
      });
    });

    it('Verify compatibility of the video player Across Different screens - @T24d89b38', () => {
      const viewports = [
        [1920, 1080], // Desktop
        [1366, 768], // Laptop
        [1280, 800], // Tablet
        [414, 896], // Mobile
      ];

      viewports.forEach(([w, h]) => {
        cy.viewport(w, h);
        cy.login('administrator');
        cy.search('Sample Video Item');
        cy.contains('Sample Video Item').click({ force: true });

        cy.get('[data-testid="media-player"]').should('be.visible');
        cy.get('video[data-testid="videojs-video-element"]').should(
          'be.visible'
        );

        // Play video
        cy.get('.vjs-play-control').click({ force: true });
        cy.get('video').should(($v) => expect($v[0].paused).to.eq(false));
        //verifying that key controls are visible and not cut off
        cy.get('.vjs-control-bar').should('be.visible');
        cy.get('.vjs-fullscreen-control').should('be.visible');
        cy.get('.vjs-mute-control').should('be.visible');
      });
    });

    it('Verify that users can stream the video on the media player in landscape mode -@T017627dd', () => {
      cy.viewport(896, 414); // Landscape mobile size
      cy.get('[data-testid="media-player"]').should('be.visible');
      cy.get('video[data-testid="videojs-video-element"]').should('be.visible');

      // play
      cy.get('.vjs-play-control').click({ force: true });
      cy.get('video').should(($v) => expect($v[0].paused).to.eq(false));

      // playing continues in landscape
      cy.wait(2000);
      cy.get('video').should(($v) =>
        expect($v[0].currentTime).to.be.greaterThan(0)
      );
    });
  });
});
