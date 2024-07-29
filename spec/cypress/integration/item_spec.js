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

context('Item', () => {
  //Create dynamic items here
  const collection_title = Cypress.env('SEARCH_COLLECTION');
  var item_title = `Automation Item title ${Math.floor(Math.random() * 100000) + 1}`
  //Fallback for item id. It will be updated later once the creating an item under a collection is executed
  let item_id = Cypress.env('MEDIA_OBJECT_ID_2');

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
    cy.contains('a', collection_title).click();
    cy.contains('a', 'Create An Item').click();

    // Upload a video from fixtures and continue
    // cy.get('li.nav-item.nav-success').contains('a.nav-link', 'Manage files').click();
    const videoName = 'test_sample.mp4';
    cy.get('div#file-upload input[type="file"][name="Filedata[]"]').selectFile(
      `spec/cypress/fixtures/${videoName}`,
      { force: true }
    );
    cy.wait(5000);

    // Click the Upload button to submit the form, force the click action
    cy.get('div#file-upload a.fileinput-submit').click({ force: true });

    // Wait for the upload process to complete (you might need to wait for a success message or network request)
    cy.wait(5000);

    // Verify that the file appears in the list of uploaded files and save and continue
    cy.get('#associated_files .card-body').should('contain', videoName); // Adjust the selector as needed
    cy.get('input[name="save_and_continue"][value="Continue"]').click();

    // Fill the mandatory fields in the resource description and save and continue
    cy.get('input#media_object_title')
      .type(item_title)
      .should('have.value', item_title);
    const publicationYear = String(
      Math.floor(Math.random() * (2020 - 1900 + 1)) + 1900
    );
    cy.get('input#media_object_date_issued')
      .type(publicationYear)
      .should('have.value', publicationYear);
    cy.get(
      'input[name="save_and_continue"][value="Save and continue"]'
    ).click();

    // Navigate to the preview page by passing through structure and access control page
	//structure page
	cy.get(
		'input[name="save_and_continue"][value="Continue"]'
	  ).click()
	//Access control page
	cy.get(
		'input[name="save_and_continue"][value="Save and continue"]'
	  ).click()

	
    // Validate the item title, collection, and publication date
    cy.get('.page-title-wrapper h2').should('contain.text', item_title);

    cy.get('div.ramp--tabs-panel').within(() => {
      cy.get('div.tab-content dt')
        .contains('Date')
        .next('dd')
        .should('have.text', publicationYear);
      cy.get('div.tab-content dt')
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
    cy.visit('/media_objects/' + item_id);
    cy.get('#administrative_options a').contains('Publish').click();

    //validate success message
    cy.get('div.alert p').contains('1 media object successfully published.');
    cy.get('#administrative_options a').contains('Unpublish');

    //reload the page to ensure that the data is updated in the backend
    cy.reload();
    cy.get('#administrative_options a').contains('Unpublish');
  });


  it('Verify setting Item access to “Collections staff only” for a published item - @T13b097f8', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.visit('/media_objects/' + item_id+'/edit?step=access-control');
    cy.get('.item-access').within(() => {
      cy.contains('label', 'Collection staff only')
        .find('input[type="radio"]')
        .click()
        .should('be.checked');
    });
    cy.get('input[type="submit"][name="save"]').click();

    //Login as a user who is not a staff to collection to validate the result
    //login as a user who is a staff to the collection and verify that the item is accessible
  });

  it('Verify setting Item access to “Logged in users only” for a published item - @T0cc6ee02', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.visit('/media_objects/' + item_id+'/edit?step=access-control');
    cy.get('.item-access').within(() => {
      cy.contains('label', 'Logged in users only')
        .find('input[type="radio"]')
        .click()
        .should('be.checked');
    });
    cy.get('input[type="submit"][name="save"]').click();
    //reload the page to ensure that the data is updated in the backend

    //Logout of the application and verify that the item is not visible
    //login as any non collection staff user and validate the result
  });

  it('Verify setting Item access to “Available to general public” for a published item - @T593dc580', () => {
    cy.login('administrator');
    cy.visit('/');
    cy.visit('/media_objects/' + item_id+'/edit?step=access-control');
    cy.get('.item-access').within(() => {
      cy.contains('label', 'Available to the general public')
        .find('input[type="radio"]')
        .click()
        .should('be.checked');
    });
    cy.get('input[type="submit"][name="save"]').click();
    //reload the page to ensure that the data is updated in the backend

    //Verify item access without logging in
  });

  it('Verify setting Special access for an Avalon user - published item - @Ta15294e5', () => {
    cy.login('administrator');
    cy.visit('/');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.visit('/media_objects/' + item_id+'/edit?step=access-control');
    const user_username = Cypress.env('USERS_USER_USERNAME');
    //Assign special access - Avalon user (who is not associated with the collection)
    cy.get('.card.special-access')
      .find('input#add_user_display')
      .type(user_username)
      .should('have.value', user_username);
    cy.get('input[id="add_user_display"]')
      .closest('.form-group') // Find the closest form-group div that contains this input
      .find('button[name="submit_add_user"]')
      .click();
    cy.get('input[type="submit"][name="save"]').click();
    //reload the page to ensure that the data is updated in the backend

    //Login as the special access user and validate the result
  });


  it('Verify that modifying the resource metadata fields are reflected properly in the preview section- @T16bc91af', () => {
    cy.login('administrator');
    cy.visit('/');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.visit('/media_objects/' + item_id);
    cy.get('#administrative_options').find('a.btn').contains('Edit').click();
    cy.get('li.nav-item.nav-success')
      .contains('a.nav-link', 'Resource description')
      .click();

    //Add some resource metadata fields in the resource description section
    //More fields can be added if required.
    const main_contributor = Cypress.env('MEDIA_OBJECT_FIELD_MAIN_CONTRIBUTOR');
    const language = Cypress.env('MEDIA_OBJECT_FIELD_LANGUAGE');
    const summary =
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.";

    cy.get('input#media_object_creator_0')
      .clear()
      .type(main_contributor)
      .should('have.value', main_contributor);
    cy.get('input#display_media_object_language_0')
      .clear()
      .type(language)
      .should('have.value', language);
    cy.get('textarea#abstract_0')
      .clear()
      .type(summary)
      .should('have.value', summary);
    cy.get(
      'input[name="save_and_continue"][value="Save and continue"]'
    ).click();

    // Navigate to the preview page
    cy.get('li.nav-item.nav-success').contains('a.nav-link', 'Preview').click();

    //Validate the fields
    cy.get('div.ramp--tabs-panel').within(() => {
      cy.get('div.tab-content dt')
        .contains('Summary')
        .next('dd')
        .should('have.text', summary);

      // Validate the "Language" field
      cy.get('div.tab-content dt')
        .contains('Language')
        .next('dd')
        .should('have.text', language);

      // Validate the "Main contributor" field
      cy.get('div.tab-content dt')
        .contains('Main contributor')
        .next('dd')
        .should('have.text', main_contributor);
    });
  });

  it('Verify modifying the resource metadata of an item reflects in the index- @Tec49689f', () => {
    cy.login('administrator');
    cy.visit('/');
    // The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
    cy.visit('/media_objects/' + item_id);
    cy.get('#administrative_options').find('a.btn').contains('Edit').click();
    cy.get('li.nav-item.nav-success')
      .contains('a.nav-link', 'Resource description')
      .click();

    //Add some resource metadata fields in the resource description section to search via index
    const genre = Cypress.env('MEDIA_OBJECT_FIELD_GENRE');

    cy.get('input#media_object_genre_0')
      .clear()
      .type(genre)
      .should('have.value', genre);
    cy.get('input[name="save"][value="Save"]').click();
    cy.get(
      'input[name="save_and_continue"][value="Save and continue"]'
    ).click();

    //Navigate to the browse section and search for the item_title
    cy.contains('a.nav-link', 'Browse').click();
    cy.get("input.global-search-input[placeholder='Search this site']")
      .first()
      .type(item_title)
      .should('have.value', item_title); // Only yield inputs within form
    cy.get('button.global-search-submit').first().click();

    //Filter using the added resource meta data ie: GENRE
    cy.contains('button', 'Genres').click();
    cy.get('span.facet-label').contains('a', genre).click();

    //Validate that the item is  indexed in the search and is shown under the correct series facet
    cy.get('div#documents').within(() => {
      cy.get('h3.index_title.document-title-heading').contains(item_title);
    });
  });

  //teardown code: delete the created item
  // Final test to run at the end
  it('Verify deleting an item - @Tf46071b7', () => {
    cy.login('administrator');
    cy.visit('/media_objects/' + item_id);
    cy.get('#administrative_options').find('a.btn').contains('Edit').click();
    cy.get('a#special_button_color').contains('Delete this item').click();
    cy.get('a#deleteLink').contains('Yes, I am sure').click();
    cy.get('div.alert').contains('1 media object deleted.');
  });
});
