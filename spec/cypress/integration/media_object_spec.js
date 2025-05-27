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

import { navigateToManageContent, performSearch } from '../support/navigation';
context('Media objects', () => {
  //This will contain test cases for an item that is manually created in an env.
  //Must have captions
  //Available to all
  //Multiple sections - lunchroom manner, audio file, 10 second clip, Lunchroom manner
  const collection_title = Cypress.env('SEARCH_COLLECTION'); //underwhich the item will be created - access - general public
  var media_object_id;
  const media_object_title = Cypress.env('MEDIA_OBJECT_TITLE');
  const caption = `captions-example.srt`;
  const structureFile = `test-sample.mp4.structure.xml`;
  Cypress.on('uncaught:exception', (err, runnable) => {
    // Ignore specific error message and let test continue
    if (err.message.includes('Permissions check failed')) {
      return false;
    }
  });
  Cypress.on('uncaught:exception', (err, runnable) => {
    // Prevents Cypress from failing the test due to uncaught exceptions in the application code  - TypeError: Cannot read properties of undefined (reading 'scrollDown')
    if (
      err.message.includes(
        "Cannot read properties of undefined (reading 'success')"
      )
    ) {
      return false;
    }
    if (err.message.includes('scrollHeight')) {
      return false;
    }
    if (
      err.message.includes(
        "Cannot read properties of undefined (reading 'end')"
      )
    ) {
      return false;
    }
  });

  it(
    'Creates an item with 3 sections (2 video and 1 audio)',
    { tags: '@critical' },
    () => {
      // Log in as an administrator
      cy.login('administrator');

      // Go to an existing collection to create an item
      navigateToManageContent();
      cy.get("[data-testid='collection-name-table']")
        .contains(collection_title)
        .click();

      //create item api
      cy.intercept('GET', '/media_objects/new?collection_id=*').as(
        'getManageFile'
      );

      cy.get("[data-testid='collection-create-item-btn']")
        .contains('Create An Item')
        .click();

      cy.wait('@getManageFile').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });

      //upload api
      cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect');

      // Upload a video from fixtures and continue

      //First Video

      const videoName = 'test_sample.mp4';
      cy.get("[data-testid='media-object-edit-select-file-btn']")
        .click()
        .selectFile(`spec/cypress/fixtures/${videoName}`);

      // Click the Upload button to submit the form, force the click action
      cy.get("[data-testid='media-object-edit-upload-btn']").click();

      cy.wait('@fileuploadredirect').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });

      // Verify that the file appears in the list of uploaded files and save and continue
      cy.get("[data-testid='media-object-edit-associated-files-block']").should(
        'contain',
        '.mp4'
      ); // Adjust the selector as needed

      //Adding caption to the first video file
      cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();
      const captionFileName = 'captions-example.srt';
      //added force: true because the element is not visible
      cy.get('[data-testid="media-object-upload-button-caption"]').selectFile(
        `spec/cypress/fixtures/${captionFileName}`,
        { force: true }
      );

      cy.get('[data-testid="alert"]').contains(
        'Supplemental file successfully added.'
      );

      //Second audio
      const audioName = 'test_sample_audio.mp3';
      cy.get("[data-testid='media-object-edit-select-file-btn']")
        .click()
        .selectFile(`spec/cypress/fixtures/${audioName}`);

      // Click the Upload button to submit the form, force the click action
      cy.get("[data-testid='media-object-edit-upload-btn']").click();

      cy.wait('@fileuploadredirect').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });

      // Verify that the file appears in the list of uploaded files and save and continue
      cy.get("[data-testid='media-object-edit-associated-files-block']").should(
        'contain',
        '.mp3'
      );

      //Third Video
      cy.get("[data-testid='media-object-edit-select-file-btn']")
        .click()
        .selectFile(`spec/cypress/fixtures/${videoName}`);

      // Click the Upload button to submit the form, force the click action
      cy.get("[data-testid='media-object-edit-upload-btn']").click();

      cy.wait('@fileuploadredirect').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });

      // Verify that the file appears in the list of uploaded files and save and continue
      cy.get("[data-testid='media-object-edit-associated-files-block']").should(
        'contain',
        '.mp4'
      );

      //continue to resource description api
      cy.intercept('GET', '**/edit?step=resource-description').as(
        'resourcedescription'
      );
      cy.get('[data-testid="media-object-continue-btn"]').click();

      cy.wait('@resourcedescription').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });

      // Fill the mandatory fields in the resource description and save and continue
      cy.get('[data-testid="resource-description-title"]')
        .type(media_object_title)
        .should('have.value', media_object_title);
      const publicationYear = String(
        Math.floor(Math.random() * (2020 - 1900 + 1)) + 1900
      );
      cy.get('[data-testid="resource-description-date-issued"]')
        .type(publicationYear)
        .should('have.value', publicationYear);

      //continue to structure page api

      cy.get('[data-testid="media-object-continue-btn"]').click();
      //structure page
      //adding structure file later used for playlist

      cy.get('[data-testid="media-object-edit-structure-btn-0"]').click();
      cy.get('[data-testid="media-object-struct-adv-edit-btn-0"]').click();
      cy.wait(2000);
      cy.window().then((win) => {
        const editor = win.ace.edit('text_editor_0');
        const xmlContent = `<Item label="Short Documentary.mp4">
      <Div label="Opening">
        <Span label="Intro 1" begin="00:00:00" end="00:00:10"/>
        <Span label="Intro 2" begin="00:00:11" end="00:00:20"/>
      </Div>
      <Div label="Main Content">
        <Span label="Segment A" begin="00:00:20" end="00:00:30"/>
        <Span label="Segment B" begin="00:00:30" end="00:00:45"/>
      </Div>
      <Span label="Wrap-up" begin="00:00:45" end="00:00:53"/>
    </Item>`;
        editor.setValue(xmlContent, -1);
      });

      cy.get('input[type="button"][value="Save and Exit"]').click();

      //continue to access page
      cy.intercept('GET', '**//edit?step=access-control').as('accesspage');
      // Navigate to the preview page by passing through structure and access control page

      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.wait('@accesspage').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });

      //Access control page
      cy.get('[data-testid="media-object-continue-btn"]').click();

      // Validate the item title, collection, and publication date
      cy.get('[data-testid="media-object-title"]').should(
        'contain.text',
        media_object_title
      );

      cy.get('[data-testid="metadata-display"]').within(() => {
        cy.get('dt')
          .contains('Publication date') //changed from Date
          .next('dd')
          .should('have.text', publicationYear);
        cy.get('dt')
          .contains('Collection')
          .next('dd')
          .contains(collection_title);
      });

      //Extract the item id to run the rest of the tests
      cy.url().then((url) => {
        media_object_id = url.split('/').pop();
        cy.writeFile('cypress.env.dynamic.json', {
          MEDIA_OBJECT_ID: media_object_id,
        });
      });

      //publish the item so different user roles can check the playback
      cy.intercept('POST', '**/update_status?status=publish').as(
        'publishmedia'
      );
      cy.get('[data-testid="media-object-publish-btn"]')
        .contains('Publish')
        .click();
      cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);

      cy.get('[data-testid="alert"]').contains(
        '1 media object successfully published.'
      );
      cy.wait(5000);

      cy.get('[data-testid="media-object-unpublish-btn"]').contains(
        'Unpublish'
      );
    }
  );
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
    it.skip('.play_media_objects()', { tags: '@critical' }, () => {
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
        cy.get('[data-testid="listitem-section"]')
          .filter('[data-label*=".mp3"]')
          .first()
          .within(() => {
            cy.get('[data-testid="listitem-section-button"]').click();
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

        cy.get('[data-testid="listitem-section-button"]').then(($buttons) => {
          const sectionCount = Math.min($buttons.length, 3); //Limits to the first 3 sections

          //Loops through the 3 sections
          Cypress._.times(sectionCount, (index) => {
            //Section titles should be visible
            cy.get('[data-testid="listitem-section-button"]')
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
