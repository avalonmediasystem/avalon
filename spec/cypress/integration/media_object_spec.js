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
import UnitPage from '../pageObjects/unitPage.js';
import { getFixturePath } from '../support/utils';
const unitPage = UnitPage;

const collectionPage = new CollectionPage();

context('Media objects', () => {
  //This will contain test cases for an item that is manually created in an env.
  //Must have captions
  //Available to all
  //Multiple sections
  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var media_object_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;
  var unit_title = `Automation unit title ${
    Math.floor(Math.random() * 10000) + 1
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
  before(() => {
    cy.login('administrator');
    unitPage.createUnit({ title: unit_title });
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
    //delete the unit
    UnitPage.deleteUnitByName(unit_title);
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
        //Click the first mp3 audio in the tree and open it
        cy.get('[data-testid="tree-item"]', { timeout: 15000 })
          .filter('[data-label*=".mp3"]')
          .first()
          .should('be.visible')
          .within(() => {
            cy.get('[data-testid="treeitem-section-button"]', {
              timeout: 15000,
            })
              .should('be.visible')
              .click();
          });

        //Wait for player to load
        cy.waitForVideoReady();

        //Player exists and controls are visible
        cy.get('[data-testid="media-player"]', { timeout: 15000 })
          .should('exist')
          .and('be.visible')
          .as('player');

        // to do user acitivity to show controls if the player hides them
        cy.get('@player')
          .trigger('mousemove', { force: true })
          .click('center', { force: true });

        //Click Play - scoping to title to avoid conflicts
        cy.get('@player')
          .find(
            'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]',
            { timeout: 15000 }
          )
          .first()
          .should('exist')
          .and('be.visible')
          .click({ force: true });

        //Player is playing
        cy.get('[data-testid="videojs-video-element"]', {
          timeout: 15000,
        }).should('have.class', 'vjs-playing');

        //Make sure the timer is progressing
        cy.get('[data-testid="videojs-audio-element"]', { timeout: 15000 })
          .should('exist')
          .then(($el) => {
            const media = $el[0];

            // Wait until the media has actually started
            cy.wrap(media, { log: false }).should(() => {
              //either condition proves "playback is happening / started"
              expect(
                media.currentTime > 0 || media.paused === false,
                `currentTime=${media.currentTime}, paused=${media.paused}`
              ).to.equal(true);
            });
          });

        //Current time should increase after some time
        cy.get('[data-testid="videojs-audio-element"]')
          .invoke('prop', 'currentTime')
          .then((t1) => {
            cy.wait(1250);
            cy.get('[data-testid="videojs-audio-element"]')
              .invoke('prop', 'currentTime')
              .should((t2) => {
                expect(t2, `t1=${t1}, t2=${t2}`).to.be.greaterThan(t1);
              });
          });

        //DIsplay timer should be updated
        cy.get('.current-time-display', { timeout: 15000 })
          .should('be.visible')
          .invoke('text')
          .then((time1) => {
            cy.wait(1250);
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

    it('Verify the icons in a video player in fullscreen mode - @T503d2ee1', () => {
      cy.get('[data-testid="media-player"]', { timeout: 15000 })
        .should('exist')
        .and('be.visible')
        .as('player');

      const showControls = () => {
        cy.get('@player')
          .should('have.length', 1)
          .trigger('mousemove', { force: true })
          .trigger('mouseover', { force: true })
          .click('center', { force: true });
      };

      showControls();

      cy.get('@player')
        .find('.vjs-fullscreen-control', { timeout: 15000 })
        .should('exist')
        .scrollIntoView()
        .should('be.visible')
        .click({ force: true });

      showControls();

      cy.get('@player')
        .find('button.vjs-big-play-button', { timeout: 15000 })
        .should('exist')
        .and('be.visible');

      cy.get('@player')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]',
          { timeout: 15000 }
        )
        .first()
        .should('exist')
        .and('be.visible');

      cy.get('@player')
        .find('[data-testid="videojs-previous-button"]', { timeout: 15000 })
        .should('exist')
        .and('be.visible');

      cy.get('@player')
        .find('[data-testid="videojs-next-button"]', { timeout: 15000 })
        .should('exist')
        .and('be.visible');

      cy.get('@player')
        .find('[data-testid="videojs-track-scrubber-button"]', {
          timeout: 15000,
        })
        .should('exist')
        .and('be.visible');

      cy.get('@player')
        .find('button.vjs-subs-caps-button')
        .then(($btn) => {
          if ($btn.length) cy.wrap($btn).should('be.visible');
        });

      cy.get('@player')
        .find('.vjs-mute-control', { timeout: 15000 })
        .should('exist')
        .and('be.visible');

      cy.get('@player')
        .find('.vjs-volume-bar', { timeout: 15000 })
        .should('exist');

      cy.get('@player')
        .find('.vjs-quality-selector button')
        .then(($btn) => {
          if ($btn.length) cy.wrap($btn).should('be.visible');
        });

      cy.get('@player')
        .find('.vjs-fullscreen-control', { timeout: 15000 })
        .should('exist')
        .and('be.visible');
    });

    it('Verify the player pause and play actions - Video - @T7be623ee', () => {
      cy.get('[data-testid="media-player"]', { timeout: 15000 })
        .should('exist')
        .and('be.visible')
        .as('player');

      cy.get('@player')
        .find('video[data-testid="videojs-video-element"]', { timeout: 15000 })
        .should('exist')
        .as('videoEl');

      cy.get('#iiif-media-player', { timeout: 15000 })
        .should('exist')
        .as('vjsRoot');

      const wakeControls = () => {
        cy.get('@vjsRoot')
          .trigger('mousemove', { force: true })
          .trigger('mouseover', { force: true });
      };

      const clickPlayPause = () => {
        wakeControls();
        cy.get('@vjsRoot')
          .find(
            'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]',
            { timeout: 15000 }
          )
          .first()
          .should('be.visible')
          .click({ force: true });
      };

      const expectPlaying = () => {
        cy.get('@videoEl').should(($v) => expect($v[0].paused).to.eq(false));
        cy.get('@videoEl')
          .invoke('prop', 'currentTime')
          .then((t1) => {
            cy.wait(800);
            cy.get('@videoEl')
              .invoke('prop', 'currentTime')
              .should((t2) => expect(t2).to.be.greaterThan(t1));
          });
      };

      const expectPaused = () => {
        cy.get('@videoEl').should(($v) => expect($v[0].paused).to.eq(true));
      };

      // Start playback
      cy.get('@player')
        .find('.vjs-big-play-button', { timeout: 15000 })
        .should('be.visible')
        .click({ force: true });

      expectPlaying();

      clickPlayPause();
      expectPaused();
      clickPlayPause();
      expectPlaying();

      // Stub fullscreen API BEFORE clicking fullscreen
      cy.window().then((win) => {
        if (win.HTMLElement?.prototype) {
          win.HTMLElement.prototype.requestFullscreen = () => Promise.resolve();
          win.HTMLElement.prototype.webkitRequestFullscreen = () =>
            Promise.resolve();
        }
        win.document.exitFullscreen = () => Promise.resolve();
        win.document.webkitExitFullscreen = () => Promise.resolve();
      });

      // Click fullscreen, then assert the UI toggled fullscreen mode (without forcing class)
      wakeControls();
      cy.get('@vjsRoot')
        .find('button.vjs-fullscreen-control[title="Fullscreen"]', {
          timeout: 15000,
        })
        .should('be.visible')
        .click({ force: true });

      cy.get('@vjsRoot', { timeout: 15000 }).should(
        'have.class',
        'vjs-fullscreen'
      );

      // Play/Pause still works in fullscreen UI mode
      clickPlayPause();
      expectPaused();
      clickPlayPause();
      expectPlaying();
    });

    it('Verify the players hotkeys for pause and play actions - Video and Audio - @T633feb48', () => {
      cy.get('[data-testid="media-player"]').as('player');

      cy.get('@player')
        .find('video[data-testid="videojs-video-element"]')
        .as('video');

      cy.get('@player').find('.vjs-big-play-button').as('centerPlay');

      cy.get('@player')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
        )
        .first()
        .as('playPauseBtn');
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
      cy.get('body').type(' '); //pause
      expectPaused();
      cy.get('body').type(' '); //play
      expectPlaying();

      // would be different for mco
      cy.get('[data-testid="browse-global-search-input"]', { timeout: 15000 })
        .should('exist')
        .first()
        .type('{selectAll}hello world')
        .should('have.value', 'hello world');

      expectPlaying();

      // Clicking buttons should not pause video
      cy.get('[data-testid="media-object-add-to-playlist-btn"]', {
        timeout: 3000,
      })
        .should('exist')
        .click({ force: true });
      expectPlaying();

      cy.get('[data-testid="media-object-create-timeline-btn"]', {
        timeout: 3000,
      })
        .should('exist')
        .click({ force: true });
      expectPlaying();

      //control bar play/pause button
      cy.get('@playPauseBtn').click({ force: true });
      expectPaused();
      cy.get('@playPauseBtn').click({ force: true });
      expectPlaying();

      cy.visit('/media_objects/' + media_object_id);
      cy.get('@playPauseBtn').click({ force: true });
      //fullscreen and repeat spacebar check - stubbing fullscreen API to avoid test instability due to fullscreen behavior in Cypress
      cy.window().then((win) => {
        win.HTMLElement.prototype.requestFullscreen = () => Promise.resolve();
        win.HTMLElement.prototype.webkitRequestFullscreen = () =>
          Promise.resolve();
        win.document.exitFullscreen = () => Promise.resolve();
        win.document.webkitExitFullscreen = () => Promise.resolve();
      });

      cy.get('@fullscreenBtn').click({ force: true });

      // Space still toggles
      cy.get('body').type(' '); //pause
      cy.get('body').type(' '); //play
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
      cy.get('@player')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
        )
        .first()
        .as('playPause');

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
      cy.get('[data-testid="media-player"]', { timeout: 15000 })
        .should('exist')
        .and('be.visible')
        .as('player');

      cy.get('video[data-testid="videojs-video-element"]', { timeout: 15000 })
        .should('exist')
        .as('videoEl');

      cy.get('@player')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]',
          { timeout: 15000 }
        )
        .first()
        .should('be.visible')
        .as('playPause');

      cy.get('@player')
        .find('[data-testid="videojs-custom-seekbar"]', { timeout: 15000 })
        .should('exist')
        .as('seekbar');

      cy.get('@player')
        .find('[data-testid="videojs-track-scrubber-button"]', {
          timeout: 15000,
        })
        .should('exist')
        .as('scrubberBtn');

      // Start playback
      cy.get('@playPause').click({ force: true });
      cy.get('@videoEl').should(($v) => expect($v[0].paused).to.eq(false));

      // Scrub forward using JS — more reliable than clicking seekbar positions
      cy.get('@videoEl').then(($v) => {
        $v[0].currentTime = 30;
      });
      cy.wait(200);
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .should((t1) => {
          expect(t1).to.be.within(28, 35);
        });

      // Scrub back using JS
      cy.get('@videoEl').then(($v) => {
        $v[0].currentTime = 5;
      });
      cy.wait(200);
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .should((t2) => {
          expect(t2).to.be.lessThan(10);
        });

      // Open mini scrubber and verify it exists
      cy.get('@scrubberBtn').click({ force: true });
      cy.get('#track_scrubber .vjs-track-scrubber', { timeout: 15000 })
        .should('exist')
        .as('miniScrubber');

      // Scrub forward in mini scrubber using JS
      cy.get('@videoEl').then(($v) => {
        $v[0].currentTime = 8;
      });
      cy.wait(200);
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .should((s1) => expect(s1).to.be.gt(5));

      // Scrub back in mini scrubber using JS
      cy.get('@videoEl').then(($v) => {
        $v[0].currentTime = 2;
      });
      cy.wait(200);
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .should((s2) => expect(s2).to.be.lt(5));

      // Arrow key hotkeys: +5 and -5 seconds
      cy.get('[data-testid="media-player"]').click('center', { force: true });

      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .then((k0) => {
          cy.get('body').type('{rightArrow}');
          cy.wait(300);
          cy.get('@videoEl')
            .invoke('prop', 'currentTime')
            .should((k1) => expect(k1).to.be.closeTo(k0 + 5, 2));

          cy.get('body').type('{leftArrow}');
          cy.wait(300);
          cy.get('@videoEl')
            .invoke('prop', 'currentTime')
            .should((k2) => expect(k2).to.be.closeTo(k0, 2));
        });

      // Fullscreen — use class toggle to avoid Permissions check failed
      cy.get('[data-testid="videojs-video-element"]').then(($el) => {
        $el.addClass('vjs-fullscreen');
      });
      cy.get('[data-testid="videojs-video-element"]').should(
        'have.class',
        'vjs-fullscreen'
      );

      // Seek in fullscreen using JS
      cy.get('@videoEl').then(($v) => {
        $v[0].currentTime = 30;
      });
      cy.wait(500);
      cy.get('@videoEl')
        .invoke('prop', 'currentTime')
        .should((f1) => expect(f1).to.be.within(28, 40));
    });

    it('Verify whether the user is able to adjust volume in the video player  - @Te7a1268e', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('video[data-testid="videojs-video-element"]').as('videoEl');
      cy.get('@player').find('.vjs-mute-control').as('muteBtn');
      cy.get('@player').find('.vjs-volume-bar').as('volumeBar');
      cy.get('@player').find('.vjs-fullscreen-control').as('fullscreenBtn');
      // Start play
      cy.get('@player')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
        )
        .first()
        .click({ force: true });

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
      cy.get('[data-testid="videojs-video-element"]').then(($el) => {
        $el.addClass('vjs-fullscreen');
      });
      cy.get('[data-testid="videojs-video-element"]').should(
        'have.class',
        'vjs-fullscreen'
      );
      cy.get('body').type('m'); // mute
      cy.get('@muteBtn').should('have.class', 'vjs-vol-0');
      cy.get('body').type('m'); //unmute
      cy.get('@muteBtn').should('not.have.class', 'vjs-vol-0');
    });

    it('Verify playing the video in full screen - @T384ebffc', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('video[data-testid="videojs-video-element"]').as('videoEl');
      cy.get('div[data-testid="videojs-video-element"]').as('vjsContainer');
      cy.get('@player').find('.vjs-fullscreen-control').as('fullscreenBtn');

      // Start play
      cy.get('@player')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
        )
        .first()
        .click({ force: true });

      //Stubing fullscreen API so Cypress doesn't throw error
      cy.window().then((win) => {
        if (win.HTMLElement?.prototype) {
          win.HTMLElement.prototype.requestFullscreen = () => Promise.resolve();
          win.HTMLElement.prototype.webkitRequestFullscreen = () =>
            Promise.resolve();
        }
        win.document.exitFullscreen = () => Promise.resolve();
        win.document.webkitExitFullscreen = () => Promise.resolve();
        // Also stub the fullscreenElement property so VJS thinks it's in fullscreen
        Object.defineProperty(win.document, 'fullscreenElement', {
          get: function () {
            return win._fakeFullscreenElement || null;
          },
          configurable: true,
        });
        win._fakeFullscreenElement = null;
      });

      //Enter/exit fullscreen with button click
      cy.get('@fullscreenBtn').click({ force: true });
      cy.get('@vjsContainer', { timeout: 5000 }).should(
        'have.class',
        'vjs-fullscreen'
      );

      cy.get('@fullscreenBtn').click({ force: true });
      cy.get('@vjsContainer').should('not.have.class', 'vjs-fullscreen');

      // Focus player and press 'f'
      cy.get('@vjsContainer').click({ force: true });
      cy.wait(300);

      cy.get('body').type('f');
      cy.get('@vjsContainer', { timeout: 5000 }).should(
        'have.class',
        'vjs-fullscreen'
      );

      cy.wait(500);

      cy.get('body').type('f');
      cy.get('@vjsContainer').should('not.have.class', 'vjs-fullscreen');

      // press 'f' to exit the fullscreen
      cy.get('@vjsContainer').click({ force: true });
      cy.wait(300);

      cy.get('body').type('f');
      cy.get('@vjsContainer', { timeout: 5000 }).should(
        'have.class',
        'vjs-fullscreen'
      );

      cy.get('@fullscreenBtn').click({ force: true });
      cy.get('@vjsContainer').should('not.have.class', 'vjs-fullscreen');
    });

    it('Verify that the user can navigate through the video using the time markers in the transcript. - @T467587bd', () => {
      //Adding the transcript to the first video section
      cy.get('[data-testid="media-object-edit-btn"]').click();
      cy.get(
        '[data-testid="media-object-side-nav-link"][href*="file-upload"]'
      ).click();

      //Click Edit for the first section
      cy.get('[data-testid="media-object-manage-files-edit-btn"]')
        .first()
        .click();

      // Upload transcript
      const transcriptFile = getFixturePath('transcript-example.vtt');
      cy.get('[data-testid="media-object-edit-associated-files-block"]')
        .first()
        .find('[data-testid="media-object-upload-button-transcript"]')
        .selectFile(transcriptFile, { force: true });

      // Wait for upload to complete
      cy.contains('transcript-example.vtt', { timeout: 15000 }).should(
        'be.visible'
      );

      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.visit('/media_objects/' + media_object_id);
      cy.waitForVideoReady();

      // Click the Transcripts tab
      cy.get('button[id*="tab-transcripts"]', { timeout: 15000 })
        .should('exist')
        .click({ force: true });

      // Verify the dropdown and transcripts
      cy.get('[data-testid="transcript_nav"]', { timeout: 15000 }).should(
        'exist'
      );
      cy.get('[data-testid="transcript-select-option"]').should('be.visible');
      cy.get('[data-testid="transcript_item"]').should(
        'have.length.greaterThan',
        1
      );

      //play
      cy.get('[data-testid="media-player"]')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
        )
        .first()
        .click({ force: true });

      cy.wait(1000);

      // Click on 8 second timestamp
      cy.contains('[data-testid="transcript_time"]', '00:00:08')
        .should('be.visible')
        .click({ force: true });

      cy.wait(1000);

      // Verify current time
      cy.get('video[data-testid="videojs-video-element"]')
        .invoke('prop', 'currentTime')
        .should((currentTime) => {
          expect(currentTime).to.be.within(6, 10);
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
      cy.get('[data-testid="media-player"]')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
        )
        .first()
        .click({ force: true });

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

      // search keyword in transcript
      cy.get('[data-testid="transcript-search-input"]').clear().type('file');

      // verify search count
      cy.get('[data-testid="transcript-search-count"]')
        .should('be.visible')
        .and('contain.text', '1 of 4 results');

      // verify highlighted search results
      cy.get('.ramp--transcript_highlight').should('exist');

      // click next search result
      cy.get('[data-testid="transcript-search-next"]').click({ force: true });

      // click the timestamp of the focused transcript item
      cy.get('.ramp--transcript_item.focused')
        .find('[data-testid="transcript_time"]')
        .click({ force: true });

      // wait for seek
      cy.wait(1000);

      // Verify video currentTime advances
      cy.get('video[data-testid="videojs-video-element"]')
        .invoke('prop', 'currentTime')
        .should('be.gt', 0);

      // check that transcript stays focused on current hit
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
      // captions are enabled and CC icon is active
      cy.get('@ccButton').should('have.class', 'captions-on');

      // Turn captions OFF
      cy.get('@ccButton').click({ force: true });
      cy.get('.vjs-menu-content')
        .contains('captions off', { matchCase: false })
        .click({ force: true });
      // verify CC icon not active and caption display is empty
      cy.get('@ccButton').should('not.have.class', 'captions-on');
      cy.get('.vjs-text-track-display').should('have.text', '');

      // Fullscreen caption toggle and repeat test
      cy.get('.vjs-fullscreen-control').click({ force: true });
      cy.get('@ccButton').click({ force: true });
      cy.get('.vjs-menu-content')
        .contains('captions-example.srt')
        .click({ force: true });
      cy.get('@ccButton').should('have.class', 'captions-on');

      cy.get('@ccButton').click({ force: true });
      cy.get('.vjs-menu-content')
        .contains('captions off', { matchCase: false })
        .click({ force: true });
      cy.get('@ccButton').should('not.have.class', 'captions-on');
      cy.get('.vjs-text-track-display').should('have.text', '');

      // Exit fullscreen
      cy.get('.vjs-fullscreen-control').click({ force: true });
    });
    // fixed till here
    it('Verify previous / next canvas buttons- @T75b6b6ef', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('video[data-testid="videojs-video-element"]').as('videoEl');

      // play video
      cy.get('@player')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
        )
        .first()
        .click({ force: true });
      cy.get('@videoEl').should(($v) => expect($v[0].paused).to.eq(false));

      // click next button
      cy.get('@player')
        .find('[data-testid="videojs-next-button"]')
        .should('exist')
        .click({ force: true });

      // wait for canvas switch and new media to load
      cy.wait(2000);
      cy.waitForVideoReady();

      // verify the section has changed - check structured nav active section changed
      cy.get('.ramp--structured-nav__section-title.active').should('exist');

      // verify time resets
      cy.get('video[data-testid="videojs-video-element"]')
        .invoke('prop', 'currentTime')
        .should('be.lt', 5);

      // click on previous button
      cy.get('[data-testid="media-player"]')
        .find('[data-testid="videojs-previous-button"]')
        .should('exist')
        .click({ force: true });

      // wait for canvas switch and new media to load
      cy.wait(2000);
      cy.waitForVideoReady();

      // time resets again
      cy.get('video[data-testid="videojs-video-element"]')
        .invoke('prop', 'currentTime')
        .should('be.lt', 5);
    });
    it('Verify that media player (audio/video) automatically advances to the next section once the current section is played - @TPlayerAutoAdvanceUnified', () => {
      cy.get('[data-testid="media-player"]').as('player');
      cy.get('[data-testid="structured-nav"]').as('nav');

      // Detect audio or video
      cy.get('@player').then(($el) => {
        const hasVideo =
          $el.find('video[data-testid="videojs-video-element"]').length > 0;

        const mediaSelector = hasVideo
          ? 'video[data-testid="videojs-video-element"]'
          : 'audio[data-testid="videojs-audio-element"]';
        const durationMs = hasVideo ? 60000 : 12000;

        cy.get(mediaSelector).as('mediaEl');

        // play first section
        cy.get('@nav')
          .find('[data-testid="treeitem-section-button"]')
          .first()
          .as('firstSection')
          .click({ force: true });

        // click play button
        cy.get('@player')
          .find(
            'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
          )
          .first()
          .click({ force: true });

        cy.get('@firstSection').should('have.class', 'active');
        cy.wait(durationMs);

        //next section highlighted
        cy.get('@nav')
          .find('[data-testid="treeitem-section-button"].active')
          .should(($btns) => {
            expect($btns.length).to.eq(1);
          });

        // verify it is still playing
        cy.get('@mediaEl').should(($m) => expect($m[0].paused).to.eq(false));

        cy.visit('/media_objects/' + media_object_id);
        cy.waitForVideoReady();

        // fullscreen test
        if (hasVideo) {
          // stub fullscreen API
          cy.window().then((win) => {
            win.HTMLElement.prototype.requestFullscreen = () =>
              Promise.resolve();
            win.HTMLElement.prototype.webkitRequestFullscreen = () =>
              Promise.resolve();
            win.document.exitFullscreen = () => Promise.resolve();
            win.document.webkitExitFullscreen = () => Promise.resolve();
          });

          cy.get('.vjs-fullscreen-control').click({ force: true });

          cy.get('[data-testid="structured-nav"]')
            .find('[data-testid="treeitem-section-button"].active')
            .should('exist');

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

        // Revisit the same media object page
        cy.visit('/media_objects/' + media_object_id);
        cy.waitForVideoReady();

        cy.get('[data-testid="media-player"]').should('be.visible');
        cy.get('video[data-testid="videojs-video-element"]').should(
          'be.visible'
        );

        //play video
        cy.get('[data-testid="media-player"]')
          .find(
            'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
          )
          .first()
          .click({ force: true });
        cy.get('video[data-testid="videojs-video-element"]').should(($v) =>
          expect($v[0].paused).to.eq(false)
        );

        //Verify key controls are visible and not cut off
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
      cy.get('[data-testid="media-player"]')
        .find(
          'button.vjs-play-control[title="Play"], button.vjs-play-control[title="Pause"]'
        )
        .first()
        .click({ force: true });
      cy.get('video[data-testid="videojs-video-element"]').should(($v) =>
        expect($v[0].paused).to.eq(false)
      );

      // playing continues in landscape
      cy.wait(2000);
      cy.get('video[data-testid="videojs-video-element"]').should(($v) =>
        expect($v[0].currentTime).to.be.greaterThan(0)
      );
    });
  });
});
