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

context('Item', () => {
  //Create dynamic items here
  const collection_title = Cypress.env('SEARCH_COLLECTION');
  var item_title = `Automation Item title ${Math.floor(Math.random() * 100000) + 1}`
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
  });



  it('Verify creating an item under a collection - @T139381a0', () => {
    // Log in as an administrator
    cy.login('administrator');

    // Visit the home page
    cy.visit('/');

    // Go to an existing collection to create an item
    cy.get('#manageDropdown').click();
    cy.contains('Manage Content').click();
    cy.get("[data-testid='collection-name-table']").contains(collection_title).click(); 

    //create item api
    cy.intercept('GET', '/media_objects/new?collection_id=*').as('getManageFile');

    cy.get("[data-testid='collection-create-item-btn']").contains('Create An Item').click();

    cy.wait('@getManageFile').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });

    //upload api
    cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect');

    // Upload a video from fixtures and continue
    // cy.get('li.nav-item.nav-success').contains('a.nav-link', 'Manage files').click();
    const videoName = 'test_sample.mp4';
    cy.get("[data-testid='media-object-edit-select-file-btn']").click().selectFile(
      `spec/cypress/fixtures/${videoName}`,
    );


    // Click the Upload button to submit the form, force the click action
    cy.get("[data-testid='media-object-edit-upload-btn']").click();

    cy.wait('@fileuploadredirect').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

    // Wait for the upload process to complete (you might need to wait for a success message or network request)
    //cy.wait(5000);

    // Verify that the file appears in the list of uploaded files and save and continue
    cy.get("[data-testid='media-object-edit-associated-files-block']").should('contain', videoName); // Adjust the selector as needed
    //continue to resource description api
    cy.intercept('GET', '**/edit?step=resource-description').as('resourcedescription');
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
    cy.get('[data-testid="media-object-continue-btn"]').click()
    cy.wait('@accesspage').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

    //Access control page
    cy.get('[data-testid="media-object-continue-btn"]').click();


    // Validate the item title, collection, and publication date
    cy.get('[data-testid="media-object-title"]').should('contain.text', item_title);

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
  });

  it('Verify whether a user can publish an item - @T1faa36d2', () => {
    cy.login('administrator');
    cy.visit('/');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.intercept('GET', '**/stream').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
    cy.intercept('POST', '**/update_status?status=publish').as('publishmedia');
    cy.get('[data-testid="media-object-publish-btn"]').contains('Publish').click();
    cy.wait('@publishmedia').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });
    //validate success message
    cy.get('[data-testid="alert"]').contains('1 media object successfully published.');
    cy.get('[data-testid="media-object-unpublish-btn"]').contains('Unpublish');

    //reload the page to ensure that the data is updated in the backend
    //why do we need to validate again?
  });

  it('Verify setting Item access to “Collections staff only” for a published item - @T13b097f8', () => {
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


  });

  it('Verify setting Item access to “Logged in users only” for a published item - @T0cc6ee02', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
    cy.visit('/media_objects/' + item_id + '/edit?step=access-control');
    cy.wait('@accesspage').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
    cy.get('[data-testid="media-object-item-access"]').within(() => {
      cy.contains('label', 'Logged in users only')
        .find('[data-testid="media-object-logged-in-users"]')
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
      cy.contains('label', 'Logged in users only')
        .find('[data-testid="media-object-logged-in-users"]')
        .should('be.checked');
    });

    //Additional assertions::
    //Logout of the application and verify that the item is not visible
    //login as any non collection staff user and validate the result
    itemPage.verifyLoggedInUserAccess(item_id);
  });

  it('Verify setting Item access to “Available to general public” for a published item - @T593dc580', () => {
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
  });

  it('Verify setting Special access for an Avalon user - published item - @Ta15294e5', () => {
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
      .and('contain', user_username).click();
    cy.screenshot()
    //update access control api
    cy.intercept('POST', '/media_objects/**').as('updateaccesscontrol');
    cy.get('[data-testid="submit-add-user"]')
      .click();
    cy.wait('@updateaccesscontrol').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });
    //reload the page to ensure that the data is updated in the backend
    // Additional assertion:: Login as the special access user and validate the result
  });


  it('Verify that modifying the resource metadata fields are reflected properly in the preview section- @T16bc91af', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.intercept('GET', '**/stream').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });


    cy.get('[data-testid="media-object-edit-btn"]').contains('Edit').click();
    cy.get('[data-testid="media-object-side-nav-link"]')
      .contains("Resource description")
      .click();

    //Add some resource metadata fields in the resource description section
    //More fields can be added if required.
    const main_contributor = Cypress.env('MEDIA_OBJECT_FIELD_MAIN_CONTRIBUTOR');
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
    cy.get(
      '[data-testid="media-object-save-btn"]'
    ).click();
    cy.wait('@updateResourceDescription').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });

    
    //Navigate to the item
    
    cy.intercept('GET', '**/stream').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

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
  });

  it('Verify modifying the resource metadata of an item reflects in the index- @Tec49689f', () => {
    cy.login('administrator');
    cy.visit('/');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.intercept('GET', '**/stream').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
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
      cy.get(
        '[data-testid="media-object-save-btn"]'
      ).click();
      cy.wait('@updateResourceDescription').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });

    //Navigate to the browse section and search for the item_title
    //Need to change according to page objects
    cy.contains('a.nav-link', 'Browse').click();
    cy.get("input.global-search-input[placeholder='Search this site']")
      .first()
      .type(item_title)
      .should('have.value', item_title); // Only yield inputs within form
    cy.get('button.global-search-submit').first().click();

    //Filter using the added resource meta data ie: GENRE
    //This comes from blacklight - would have to custom _facet_limit.html.erb
    cy.contains('button', 'Genres').click();
    cy.get('span.facet-label').contains('a', genre).click();

    //Validate that the item is  indexed in the search and is shown under the correct series facet
    cy.get('div#documents').within(() => {
      cy.get('h3.index_title.document-title-heading').contains(item_title);
    });
  });

  //This case and thus the following case may fail intermittently since the item sometimes takes too long to load, 
  //and the timeline button is disabled
  it('Verify if a user is able to create timelines under an item - @T9972f970', () => {
    cy.login('administrator');
    cy.visit('/');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.intercept('GET', '**/stream').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
    cy.intercept('POST', '/timelines').as('createTimeline');

    cy.get('[data-testid="media-object-create-timeline-btn"]').click();
    cy.get('[data-testid="media-object-modal-create-timeline-btn"]').click();
    cy.wait('@createTimeline').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });

  });

  it('Verify deleting a timeline - @T89215320', () => {
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
    cy.get('[data-testid="table-view-delete-confirmation-btn"]').contains('Yes, Delete').click();
    cy.wait('@deleteTimeline').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
    cy.get('[data-testid="alert"]').contains('Timeline was successfully destroyed.')
  });

  //teardown code: delete the created item
  // Final test to run at the end
  it('Verify deleting an item - @Tf46071b7', () => {
    cy.login('administrator');
    cy.intercept({
      method: 'GET',
      url: /\/media_objects\/.*\/section\/(?!undefined).*\/stream/
    }).as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
    cy.get('[data-testid="media-object-edit-btn"]').contains('Edit').click();
    cy.intercept('POST', '/media_objects/**').as('removeMediaObject');
    cy.get('[data-testid="media-object-delete-btn"]').contains('Delete this item').click();
    cy.get('[data-testid="media-object-delete-confirmation-btn"]').contains('Yes, I am sure').click();
    cy.wait('@removeMediaObject').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });
    cy.get('[data-testid="alert"]').contains('1 media object deleted.');
  });
});
