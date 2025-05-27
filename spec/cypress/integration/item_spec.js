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

import ItemPage from '../pageObjects/itemPage';
const itemPage = new ItemPage();

import ItemPage from '../pageObjects/itemPage';
import HomePage from '../pageObjects/homePage.js';
const itemPage = new ItemPage();
import {
  navigateToManageContent,
  selectLoggedInUsersOnlyAccess,
  performSearch,
} from '../support/navigation';
const homePage = new HomePage();
context('Item', () => {
  //Create dynamic ite
  const collection_title = Cypress.env('SEARCH_COLLECTION');
  var item_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;
  let item_id;

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
    if (err.message.includes('e is not defined')) {
      return false;
    }
    if (err.message === 'Script error.') {
      return false;
    }
  });

  it(
    'Verify creating an item under a collection - @T139381a0 ',
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
      // cy.get('li.nav-item.nav-success').contains('a.nav-link', 'Manage files').click();
      const videoName = 'test_sample.mp4';
      cy.get("[data-testid='media-object-edit-select-file-btn']")
        .click()
        .selectFile(`spec/cypress/fixtures/${videoName}`);

      // Click the Upload button to submit the form, force the click action
      cy.get("[data-testid='media-object-edit-upload-btn']").click();

      cy.wait('@fileuploadredirect').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });

      // Wait for the upload process to complete (you might need to wait for a success message or network request)
      //cy.wait(5000);

      // Verify that the file appears in the list of uploaded files and save and continue
      cy.get("[data-testid='media-object-edit-associated-files-block']").should(
        'contain',
        'mp4'
      ); // Adjust the selector as needed
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
        .type(item_title)
        .should('have.value', item_title);
      const publicationYear = String(
        Math.floor(Math.random() * (2020 - 1900 + 1)) + 1900
      );
      cy.get('[data-testid="resource-description-date-issued"]')
        .type(publicationYear)
        .should('have.value', publicationYear);

      //continue to structure page api
      cy.intercept('GET', '**/edit?step=structure').as('structurepage');
      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.wait('@structurepage').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });
      //continue to access page
      cy.intercept('GET', '**//edit?step=access-control').as('accesspage');
      // Navigate to the preview page by passing through structure and access control page
      //structure page
      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.wait('@accesspage').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });

      //Access control page
      cy.get('[data-testid="media-object-continue-btn"]').click();

      // Validate the item title, collection, and publication date
      cy.get('[data-testid="media-object-title"]').should(
        'contain.text',
        item_title
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
        item_id = url.split('/').pop(); // Extract the media object ID from the URL
      });
    }
  );

  it(
    'Verify whether a user can publish an item - @T1faa36d2',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.

      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.intercept('POST', '**/update_status?status=publish').as(
        'publishmedia'
      );
      cy.get('[data-testid="media-object-publish-btn"]')
        .contains('Publish')
        .click();
      cy.wait('@publishmedia').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });
      //validate success message
      cy.get('[data-testid="alert"]').contains(
        '1 media object successfully published.'
      );
      cy.get('[data-testid="media-object-unpublish-btn"]').contains(
        'Unpublish'
      );

      //reload the page to ensure that the data is updated in the backend
      //why do we need to validate again?
    }
  );

  it(
    'Verify setting Item access to “Collections staff only” for a published item - @T13b097f8 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
      cy.visit('/media_objects/' + item_id + '/edit?step=access-control');
      cy.wait('@accesspage').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });
      cy.get('[data-testid="media-object-item-access"]').within(() => {
        cy.contains('label', 'Collection staff only')
          .find('[data-testid="media-object-collection-staff-only"]')
          .click()
          .should('be.checked');
      });
      //update access control api
      cy.intercept('POST', '/media_objects/**').as('updateaccesscontrol');
      cy.get('[data-testid="media-object-save-btn"]').click();
      cy.wait('@updateaccesscontrol').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });
      cy.get('[data-testid="media-object-item-access"]').within(() => {
        cy.contains('label', 'Collection staff only')
          .find('[data-testid="media-object-collection-staff-only"]')
          .should('be.checked');
      });

      itemPage.verifyCollecttionStaffAccess(item_id);
    }
  );

  it(
    'Verify setting Item access to “Logged in users only” for a published item - @T0cc6ee02 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
      cy.visit('/media_objects/' + item_id + '/edit?step=access-control');
      cy.wait('@accesspage').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });
      cy.get('[data-testid="media-object-item-access"]').within(() => {
        selectLoggedInUsersOnlyAccess(); //Logged in users labels are different in mco and avalon
      });
      //update access control api
      cy.intercept('POST', '/media_objects/**').as('updateaccesscontrol');
      cy.get('[data-testid="media-object-save-btn"]').click();

      cy.wait('@updateaccesscontrol').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });
      cy.get('[data-testid="media-object-item-access"]').within(() => {
        cy.get('[data-testid="media-object-logged-in-users"]').should(
          'be.checked'
        );
      });

      //Additional assertions::
      //Logout of the application and verify that the item is not visible
      //login as any non collection staff user and validate the result
      itemPage.verifyLoggedInUserAccess(item_id);
    }
  );

  it(
    'Verify setting Item access to “Available to general public” for a published item - @T593dc580 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
      cy.visit('/media_objects/' + item_id + '/edit?step=access-control');
      cy.wait('@accesspage').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });
      cy.get('[data-testid="media-object-item-access"]').within(() => {
        cy.contains('label', 'Available to the general public')
          .find('[data-testid="media-object-general-public"]')
          .click()
          .should('be.checked');
      });
      //update access control api
      cy.intercept('POST', '/media_objects/**').as('updateaccesscontrol');
      cy.get('[data-testid="media-object-save-btn"]').click();
      cy.wait('@updateaccesscontrol').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });
      cy.get('[data-testid="media-object-item-access"]').within(() => {
        cy.contains('label', 'Available to the general public')
          .find('[data-testid="media-object-general-public"]')
          .should('be.checked');
      });

      itemPage.verifyGeneralPublicAccess(item_id);

      //Additional assertion:: Verify item access without logging in
    }
  );
  it('Verify the selected item', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.visit('/bookmarks');

    // Improved clear selected items handling
    cy.get('body').then(($body) => {
      if (
        $body.find('a.clear-bookmarks:contains("Clear selected items")').length
      ) {
        cy.get('a.clear-bookmarks:contains("Clear selected items")')
          .should('be.visible')
          .click({ force: true });
      }
    });

    homePage.getBrowseNavButton().click();
    performSearch(item_title);

    cy.get('[data-testid="browse-results-list"]', { timeout: 10000 })
      .should('exist')
      .find('article')
      .first()
      .within(() => {
        cy.contains('[data-testid^="browse-document-title-"]', item_title)
          .parentsUntil('article')
          .last()
          .find('input[type="checkbox"]')
          .check({ force: true });
      });

    cy.wait(5000);
  });

  it(
    'Verify and update access control for specific item',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/bookmarks');

      // Check if the item selected exists
      cy.get('[data-testid="browse-results-list"] article')
        .contains('a', item_title)
        .should('exist');

      // Click on update access control button
      cy.get('[data-testid="bookmark-update_access_control"]')
        .should('exist')
        .click();
      // Click on Collection Staff only
      cy.get('[data-testid="bookmark-visibility-private"]')
        .check({ force: true })
        .should('be.checked');
      // Click on submit button
      cy.get('[data-testid="bookmark-update-access-control-submit"]').click();
      //Check the alert
      cy.get('[data-testid="alert"]').contains(
        'Access controls are being updated on 1 item.'
      );

      //verifying the access
      itemPage.verifyCollecttionStaffAccess(item_id);
    }
  );

  it(
    'Verify setting Special access for an Avalon user - published item - @Ta15294e5',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
      // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
      cy.visit('/media_objects/' + item_id + '/edit?step=access-control');
      cy.wait('@accesspage').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });
      const user_username = Cypress.env('USERS_USER_USERNAME');
      //Assign special access - Avalon user (who is not associated with the collection)
      cy.get('[data-testid="media-object-user"]')
        .parent()
        .find('input:not([readonly])')
        .type(user_username)
        .should('have.value', user_username);
      cy.get('.tt-menu .tt-suggestion')
        .should('be.visible')
        .and('contain', user_username)
        .click();
      cy.screenshot();
      //update access control api
      cy.intercept('POST', '/media_objects/**').as('updateaccesscontrol');
      cy.get('[data-testid="submit-add-user"]').click();
      cy.wait('@updateaccesscontrol').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });
      //reload the page to ensure that the data is updated in the backend
      // Additional assertion:: Login as the special access user and validate the result
    }
  );

  it(
    'Verify that modifying the resource metadata fields are reflected properly in the preview section- @T16bc91af',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').contains('Edit').click();
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Resource description')
        .click();

      //Add some resource metadata fields in the resource description section
      //More fields can be added if required.
      const main_contributor = Cypress.env(
        'MEDIA_OBJECT_FIELD_MAIN_CONTRIBUTOR'
      );
      const language = Cypress.env('MEDIA_OBJECT_FIELD_LANGUAGE');
      const summary =
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.";

      cy.get('[data-testid="resource-description-creator"]')
        .clear()
        .type(main_contributor)
        .should('have.value', main_contributor);
      cy.get('[data-testid="resource-description-media-object[language][]"]')
        .parent()
        .find('input:not([readonly])') //there are two inputs, this check will select the right input
        .clear()
        .type(language)
        .should('have.value', language);
      cy.get('[data-testid="resource-description-abstract"]')
        .clear()
        .type(summary)
        .should('have.value', summary);
      //update resource description api
      cy.intercept('POST', '/media_objects/**').as('updateResourceDescription');
      cy.get('[data-testid="media-object-save-btn"]').click();
      cy.wait('@updateResourceDescription').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });

      //Navigate to the item

      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();

      //Validate the fields
      //It comes from samvera/ramp - node_modules
      cy.get('[data-testid="metadata-display"]').within(() => {
        cy.get('dt')
          .contains('Summary')
          .next('dd')
          .should('have.text', summary);

        // Validate the "Language" field
        cy.get('dt')
          .contains('Language')
          .next('dd')
          .should('have.text', language);

        // Validate the "Main contributor" field
        cy.get('dt')
          .contains('Main contributor')
          .next('dd')
          .should('have.text', main_contributor);
      });
    }
  );

  it(
    'Verify modifying the resource metadata of an item reflects in the index- @Tec49689f ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.

      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').contains('Edit').click();

      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Resource description')
        .click();

      //Add some resource metadata fields in the resource description section to search via index
      const genre = Cypress.env('MEDIA_OBJECT_FIELD_GENRE');

      cy.get('[data-testid="resource-description-genre"]')
        .clear()
        .type(genre)
        .should('have.value', genre);
      cy.intercept('POST', '/media_objects/**').as('updateResourceDescription');
      cy.get('[data-testid="media-object-save-btn"]').click();
      cy.wait('@updateResourceDescription').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });

      //Navigate to the browse section and search for the item_title
      //Need to change according to page objects
      homePage.getBrowseNavButton().click();
      //search the item title
      performSearch(item_title);
      //waiting for the results to load
      cy.get('[data-testid="browse-results-list"]', { timeout: 10000 }).should(
        'exist'
      );

      //Filter using the added resource meta data
      //This comes from blacklight - would have to custom _facet_limit.html.erb
      cy.get('[data-testid="browse-facet-group-browse-by"]').within(() => {
        cy.contains('button', 'Genres').click();
      });
      cy.get('[data-testid="browse-facet-group-browse-by"]').within(() => {
        cy.contains('a', genre).click();
      });
      /// Validate that the item is indexed in the search results
      cy.get('[data-testid="browse-results-list"]').within(() => {
        cy.contains(
          '[data-testid^="browse-document-title-"]',
          item_title
        ).should('exist');
      });
    }
  );

  it('Verify browsing items by Series ', { tags: '@high' }, () => {
    cy.login('administrator');
    cy.visit('/');

    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();
    cy.get('[data-testid="media-object-edit-btn"]').contains('Edit').click();

    cy.get('[data-testid="media-object-side-nav-link"]')
      .contains('Resource description')
      .click();

    //Add some resource metadata fields in the resource description section to search via index
    const series = Cypress.env('MEDIA_OBJECT_FIELD_SERIES');

    cy.get('[data-testid="resource-description-media-object[series][]"]')
      .filter(':visible')
      .eq(1)
      .type(series, { force: true });

    cy.wait(5000);
    cy.intercept('POST', '/media_objects/**').as('updateResourceDescription');
    cy.get('[data-testid="media-object-save-btn"]').click();
    cy.wait('@updateResourceDescription').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });

    //Navigate to the browse section and search for the item_title
    //Need to change according to page objects
    homePage.getBrowseNavButton();
    //search the item title
    performSearch(item_title);

    //waiting for the results to load
    cy.get('[data-testid="browse-results-list"]', { timeout: 10000 }).should(
      'exist'
    );

    //Filter using the added resource meta data
    //This comes from blacklight - would have to custom _facet_limit.html.erb
    cy.get('[data-testid="browse-facet-group-browse-by"]').within(() => {
      cy.contains('button', 'Series').click();
    });
    cy.get('[data-testid="browse-facet-group-browse-by"]').within(() => {
      cy.contains('a', series).click();
    });
    /// Validate that the item is indexed in the search results
    cy.get('[data-testid="browse-results-list"]').within(() => {
      cy.contains('[data-testid^="browse-document-title-"]', item_title).should(
        'exist'
      );
    });
  });

  it('Verify selecting items from the browse page', { tags: '@high' }, () => {
    cy.login('administrator');
    // Uncheck all the bookmarks we have
    cy.visit('/bookmarks');
    cy.contains('a', 'Clear selected items')
      .should('be.visible')
      .click({ force: true });

    // Get the count before - it would be 0
    cy.get('[data-role="bookmark-counter"]')
      .invoke('text')
      .then((initialCountText) => {
        const initialCount = parseInt(initialCountText.trim(), 10);
        homePage.getBrowseNavButton().click();
        // Selecting first 4 items
        cy.get('[data-testid="browse-results-list"]')
          .find('[data-testid^="browse-document-metadata-"]')
          .each(($el, index) => {
            if (index < 4) {
              const documentId = $el
                .attr('data-testid')
                .replace('browse-document-metadata-', '');
              cy.get(`[id="toggle-bookmark_${documentId}"]`).check({
                force: true,
              });
            }
          })
          .then(() => {
            cy.wait(1000);

            // Verifying the bookmark counter has updated
            cy.get('[data-role="bookmark-counter"]')
              .invoke('text')
              .then((finalCountText) => {
                const finalCount = parseInt(finalCountText.trim(), 10);
                expect(finalCount).to.eq(initialCount + 4);
              });
          });
      });
  });

  it(
    'Verify user is able to update structure of an item',
    { tags: '@critical' },
    () => {
      const heading = 'Heading Example';
      const timespan = 'Introduction';

      cy.login('administrator');
      cy.visit('/');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Structure')
        .click(); //structure page
      cy.get('[data-testid="media-object-edit-structure-btn-0"]').click(); //edit structure button
      //cy.get('[data-testid="media-object-edit-structure-react-btn"]').click(); //collapsible edit structure button
      cy.get('.ReactButtonContainer')
        .find('button')
        .contains('Edit Structure')
        .click();
      cy.wait(8000);
      //renders from ReactSME
      //verifying edit structure panel
      cy.get('[data-testid="waveform-video-player"]')
        .should('be.visible')
        .and('have.prop', 'paused', true); // Initially paused

      // Click the Play button
      cy.get('[data-testid="waveform-play-button"]').click();

      // Wait a short moment to simulate playback
      cy.wait(1000);

      // Click the Pause button
      cy.get('[data-testid="waveform-pause-button"]').click();

      // Zoom in and zoom out buttons should be visible
      cy.get('[data-testid="waveform"]').should('be.visible');
      cy.get('[data-testid="zoomview-view"]').should('be.visible');
      cy.get('[data-testid="overview-view"]').should('be.visible');

      // Zoom in and zoom out buttons
      cy.get('[data-testid="waveform-zoomin-button"]').click();
      cy.wait(300);
      cy.get('[data-testid="waveform-zoomout-button"]').click();

      //turning the volume down
      cy.get('[data-testid="waveform-toolbar"]')
        .find('[role="slider"]')
        .should('exist')
        .focus()
        .type('{leftarrow}{leftarrow}{leftarrow}') // lowering volume
        .should(($el) => {
          const value = parseInt($el.attr('aria-valuenow'));
          expect(value).to.be.lessThan(100);
        });

      //validating the volume has changed
      cy.get('[data-testid="waveform-toolbar"]')
        .find('[role="slider"]')
        .should(($el) => {
          const value = parseInt($el.attr('aria-valuenow'));
          expect(value).to.be.lessThan(100);
        });
      //Add a Heading
      cy.get('[data-testid="add-heading-button"]')
        .contains('Add a Heading')
        .click();
      cy.get('[data-testid="heading-title-form-control"]').type(heading); //Heading title
      cy.get('#headingChildOf').select(item_title); //selecting
      cy.get('#headingChildOf')
        .find(':selected')
        .should('have.text', item_title);
      cy.get('[data-testid="heading-form-save-button"]')
        .contains('Save')
        .click();

      //Add a Timespan
      cy.get('[data-testid="add-timespan-button"]')
        .contains('Add a Timespan')
        .click();
      cy.get('[data-testid="timespan-form-title"]').type(timespan).click();
      cy.get('[data-testid="timespan-form-begintime"]')
        .clear()
        .type('00:00:10.000');
      cy.get('[data-testid="timespan-form-endtime"]')
        .clear()
        .type('00:00:20.000');
      cy.get('[data-testid="timespan-form-childof"]')
        .should('be.visible')
        .select(heading);
      cy.get('[data-testid="timespan-form-childof"]') //verifying the child of dropdown
        .find(':selected')
        .should('have.text', heading);
      cy.get('[data-testid="timespan-form-save-button"]').click();

      cy.get('[data-testid="structure-save-button"]').click(); //saving the structure
      cy.contains('Saved successfully.');

      //Validating the structure
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();

      cy.get('[data-testid="listitem-section"]')
        .should('exist')
        .and('have.attr', 'data-label', item_title);

      // Within the section, find the heading
      cy.get('[data-testid="listitem-section"]')
        .contains('[data-testid="list-item"]', heading)
        .should('exist')
        .within(() => {
          cy.contains('[data-testid="list-item"]', timespan) //nested timespan
            .should('exist')
            .and('be.visible');
        });

      //Clicking on section to check if it plays the right duration
      const expectedTime = '0:10';
      cy.get('[data-testid="list-item"]').contains(timespan).click();

      // Wait briefly for the player to seek & update
      cy.wait(1000);
      cy.get('.current-time-display')
        .should('be.visible')
        .should('contain.text', expectedTime); //validating it starts from the right duration
    }
  );

  it('Adding a caption file under Manage file ', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();
    cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
    cy.get('[data-testid="media-object-side-nav-link"]')
      .contains('Manage files')
      .click();
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

    //Verifying on ramp video
    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();
    cy.get('.vjs-big-play-button').should('exist').click();

    cy.get('[data-testid="media-player"]').within(() => {
      // Access the closed captions button
      cy.get('button.vjs-subs-caps-button').as('ccButton');
      cy.get('@ccButton').click();

      // Select the caption
      cy.get('.vjs-menu-content')
        .first()
        .within(() => {
          cy.contains('li.vjs-menu-item', captionFileName).click();
        });

      // Assert that the captions are enabled
      cy.get('@ccButton').should('have.class', 'captions-on');

      // Additional verification that captions are displayed
      cy.get('.vjs-text-track-cue-eng').should('exist');
    });
  });

  it(
    'Adding a transcript file under Manage file ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Manage files')
        .click();
      cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();
      const transcriptFileName = 'transcript-example.vtt';
      //added force: true because the element is not visible
      cy.get(
        '[data-testid="media-object-upload-button-transcript"]'
      ).selectFile(`spec/cypress/fixtures/${transcriptFileName}`, {
        force: true,
      });
      cy.get('[data-testid="alert"]').contains(
        'Supplemental file successfully added.'
      );

      //Verifying on ramp video
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      //verifying the trabscript tab
      cy.get('[role="tab"][data-rb-event-key="transcripts"]')
        .should('exist')
        .click();

      // clicking on a specific time - 28 seconds
      const transcriptTime = '[00:00:28]';
      const expectedSeconds = 28;

      cy.get('[data-testid="transcript_time"]')
        .contains(transcriptTime)
        .scrollIntoView()
        .should('be.visible')
        .parents('[data-testid="transcript_item"]')
        .click();

      cy.wait(1000);

      //  Verifying that the video player has moved to the expected time
      cy.get('video')
        .should('have.prop', 'currentTime')
        .then((currentTime) => {
          expect(currentTime).to.be.closeTo(expectedSeconds, 1); //margin of 1 second
        });
    }
  );

  //This case and thus the following case may fail intermittently since the item sometimes takes too long to load,
  //and the timeline button is disabled
  it(
    'Verify if a user is able to create timelines under an item - @T9972f970 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.

      cy.visit('/media_objects/' + item_id);

      cy.intercept('POST', '/timelines').as('createTimeline');

      cy.contains('Create Timeline').click();
      cy.get('[data-testid="media-object-modal-create-timeline-btn"]').click();
      cy.wait('@createTimeline').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });
    }
  );

  it(
    'Verify timeline playback by visiting timeliner directly ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/timelines');

      cy.get('[data-testid="timeline-search-input"]')
        .type(item_title)
        .should('have.value', item_title);

      cy.get('[data-testid="timeline-table-body"]')
        .contains('a', item_title)
        .click({ force: true });

      cy.wait(20000);
      cy.get('iframe')
        .should('have.attr', 'src')
        .then((iframeSrc) => {
          const baseUrl = Cypress.config('baseUrl');
          const fullSrc = iframeSrc.startsWith('http')
            ? iframeSrc
            : `${baseUrl.replace(/\/$/, '')}${iframeSrc}`;
          cy.visit(fullSrc);
        });

      // Wait for and confirm presence of timeline info like item title
      cy.contains(item_title).should('exist');
      cy.contains('Timeline information').should('exist');

      //  Check if video is streamable
      cy.get('video')
        .should('exist')
        .then(($video) => {
          $video[0].play();
        });

      cy.get('video').should('have.prop', 'paused', false);
    }
  );

  it('Verify deleting a timeline - @T89215320 ', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.visit('/timelines');
    cy.intercept('POST', '/timelines/*').as('deleteTimeline');
    cy.get('[data-testid="timeline-search-input"]')
      .type(item_title)
      .should('have.value', item_title);
    cy.get('[data-testid="timeline-table-body"]')
      .contains('td', item_title)
      .parent('tr')
      .find('.btn-danger')
      .click();
    cy.get('[data-testid="table-view-delete-confirmation-btn"]')
      .contains('Yes, Delete')
      .click();
    cy.wait('@deleteTimeline').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
    cy.get('[data-testid="alert"]').contains(
      'Timeline was successfully destroyed.'
    );
  });

  //teardown code: delete the created item
  // Final test to run at the end
  it('Verify deleting an item - @Tf46071b7 ', { tags: '@critical' }, () => {
    cy.login('administrator');

    cy.visit('/media_objects/' + item_id);
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
});
