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
import HomePage from '../pageObjects/homePage.js';
import CollectionPage from '../pageObjects/collectionPage';
import { getFixturePath, getDownloadPath } from '../support/utils';
import UnitPage from '../pageObjects/unitPage.js';
const unitPage = UnitPage;

var unit_title = `Automation unit title ${
  Math.floor(Math.random() * 10000) + 1
}`;
const itemPage = new ItemPage();
import {
  navigateToManageContent,
  selectLoggedInUsersOnlyAccess,
  performSearch,
} from '../support/navigation';
const collectionPage = new CollectionPage();
const homePage = new HomePage();
//Structure heading and subheadings
const heading = 'Heading Example';
const timespan = 'Introduction';
context('Item', () => {
  //Create dynamic ite
  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var item_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;

  let item_id;
  let createdItems = []; // Track all created items for cleanup

  Cypress.on('uncaught:exception', (err, runnable) => {
    if (
      err.message.includes(
        "Cannot read properties of undefined (reading 'success')"
      ) ||
      err.message.includes('scrollHeight') ||
      err.message.includes('e is not defined') ||
      err.message === 'Script error.'
    ) {
      return false;
    }
  });
  // Create collection before all tests
  before(() => {
    cy.login('administrator');
    unitPage.createUnit({ title: unit_title });
    navigateToManageContent();

    // Create collection with public access for item testing
    collectionPage.createCollection(
      { title: collection_title, unitName: unit_title },
      { setPublicAccess: true, addManager: true }
    );
  });

  // Clean up after all tests - ITEM FIRST, THEN COLLECTION
  after(() => {
    cy.login('administrator');
    createdItems.forEach((id) => {
      if (id != item_id) collectionPage.deleteItemById(id);
    });
    // Then delete the collection
    collectionPage.deleteCollectionByName(collection_title);
    // Delete unit
    UnitPage.deleteUnitByName(unit_title);
  });

  it(
    'Verify creating an item under a collection - @T139381a0 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');

      collectionPage.navigateToCollection(collection_title);

      collectionPage.createItem(item_title, 'test_sample.mp4').then((id) => {
        item_id = id;
        createdItems.push(item_id);

        // Verify item was created
        cy.get('[data-testid="media-object-title"]').should(
          'contain.text',
          item_title
        );
      });
    }
  );

  it(
    'Verify creating an item under a collection - Editor',
    { tags: '@high' },
    () => {
      var item_title_editor = `Automation Item title ${
        Math.floor(Math.random() * 100000) + 1
      }`;

      let item_id_editor;
      cy.login('manager');

      collectionPage.navigateToCollection(collection_title);

      collectionPage
        .createItem(item_title_editor, 'test_sample.mp4')
        .then((id) => {
          item_id_editor = id;
          createdItems.push(item_id_editor);

          cy.intercept('POST', '**/update_status?status=publish').as(
            'publishmedia'
          );
          cy.get('[data-testid="media-object-publish-btn"]')
            .contains('Publish')
            .click();
          cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
          cy.get('[data-testid="alert"]').contains(
            'Media object successfully published.'
          );
          cy.wait(5000);
          cy.get('[data-testid="media-object-unpublish-btn"]').contains(
            'Unpublish'
          );

          // Verify item was created
          cy.get('[data-testid="media-object-title"]').should(
            'contain.text',
            item_title_editor
          );
        });
      cy.waitForVideoReady();
    }
  );

  it(
    'Verify that multiple media objects (section files) can be added during item creation',
    { tags: '@high' },
    () => {
      var item_title_multiple_section = `Automation Item title ${
        Math.floor(Math.random() * 100000) + 1
      }`;

      let item_id_multiple_section;
      cy.login('manager');
      collectionPage.navigateToCollection(collection_title);

      collectionPage
        .createComplexMediaObject(item_title_multiple_section, {
          publish: true,
          addStructure: false,
        })
        .then((id) => {
          item_id_multiple_section = id;
          createdItems.push(item_id_multiple_section);
        });
      cy.waitForVideoReady();
      cy.get('[data-testid="treeitem-section"]').should('have.length', 3);
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
        'Media object successfully published.'
      );
      cy.get('[data-testid="media-object-unpublish-btn"]').contains(
        'Unpublish'
      );
    }
  );

  it(
    'Verify uploading multiple section files to an item - @Tfaf95fbd',
    { tags: '@high' },
    () => {
      const videoName = 'test_sample.mp4';
      cy.login('administrator');

      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();

      //go to manage files page
      cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Manage files')
        .click();
      // upload first video
      cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect3');
      cy.get("[data-testid='media-object-edit-select-file-btn']")
        .click()
        .selectFile(getFixturePath(videoName));
      cy.get("[data-testid='media-object-edit-upload-btn']").click();
      cy.wait('@fileuploadredirect3')
        .its('response.statusCode')
        .should('eq', 200);
      cy.get("[data-testid='media-object-edit-associated-files-block']").should(
        'contain',
        '.mp4'
      );

      // upload second video
      cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect3');
      cy.get("[data-testid='media-object-edit-select-file-btn']")
        .click()
        .selectFile(getFixturePath(videoName));

      cy.get("[data-testid='media-object-edit-upload-btn']").click();
      cy.wait('@fileuploadredirect3')
        .its('response.statusCode')
        .should('eq', 200);
      cy.get("[data-testid='media-object-edit-associated-files-block']").should(
        'contain',
        '.mp4'
      );

      //naviagte to preview page and validate
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="treeitem-section"]').should('have.length', 3);
    }
  );

  it('Verify moving a section file - @@T92a9430a', { tags: '@high' }, () => {
    cy.login('administrator');

    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();

    // Navigate to Manage Files tab
    cy.get('[data-testid="media-object-edit-btn"]').click();
    cy.get('[data-testid="media-object-side-nav-link"]')
      .contains('Manage files')
      .click();

    // Get a valid target ID different from current item
    const targetItemId = createdItems[createdItems.length - 1];
    // Click "Move" button for the second associated file
    cy.get('[data-testid="media-object-edit-associated-files-block"]')
      .find('[data-testid="media-object-move-button"]')
      .eq(1) // second item
      .click();

    // Fill modal input with target ID
    cy.get('[data-testid="media-object-target-item-id"]')
      .clear()
      .type(targetItemId);

    // Confirm move
    cy.get('[data-testid="media-object-move-button-modal"]').click();

    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();
    cy.get('[data-testid="treeitem-section"]').should('have.length', 2);

    // Visit target item and check that structure exists
    cy.wait(4000);
    cy.visit('/media_objects/' + targetItemId);
    cy.waitForVideoReady();
    cy.get('[data-testid="treeitem-section"]').should('have.length', 4);
  });

  it('Verify deleting a section file - @@T92a9430a', { tags: '@high' }, () => {
    cy.login('administrator');

    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();

    //go to manage files page
    cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
    cy.get('[data-testid="media-object-side-nav-link"]')
      .contains('Manage files')
      .click();
    // Delete above 2 added section files
    cy.get('[data-testid="media-object-edit-associated-files-block"]').then(
      ($blocks) => {
        // Skip the first block index - 0, and delete all others
        for (let i = 1; i < $blocks.length; i++) {
          cy.wrap($blocks[i])
            .find('[data-testid="media-object-delete-button"]')
            .click();

          // Wait for and confirm the popover
          cy.get('[data-testid="table-view-delete-confirmation-btn"]').click();
        }
      }
    );

    //naviagte to preview page and validate
    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();
    cy.get('[data-testid="treeitem-section"]').should('have.length', 1);
  });

  it(
    'Verify setting Item access to “Collections staff only” for a published item - @T13b097f8 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
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
      //checking the access with admin, manager and user
      itemPage.verifyCollecttionStaffAccess(item_id);
    }
  );

  it(
    'Verify setting Item access to “Logged in users only” for a published item - @T0cc6ee02 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
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

      //checking the access with admin, manager and user
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

      //checking the access with admin, manager and user
      itemPage.verifyGeneralPublicAccess(item_id);
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
      cy.get('a[href="/bookmarks/update_access_control"]')
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
      cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
      cy.visit('/media_objects/' + item_id + '/edit?step=access-control');
      cy.wait('@accesspage').then((interception) => {
        expect(interception.response.statusCode).to.eq(200);
      });
      const user_username = Cypress.env('USERS_USER_USERNAME');
      //add special access user
      cy.get("[data-testid='add_user-user-input']")
        .type(user_username)
        .should('have.value', user_username);

      cy.get("[data-testid='add_user-popup']")
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
      cy.get('[data-testid="collection-access-label-user"]').contains(
        user_username
      );
      // Additional assertion:: Login as the special access user and validate the result
      cy.login('user');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-title"]').should(
        'contain.text',
        item_title
      );
    }
  );

  it(
    'Verify that modifying the resource metadata fields are reflected properly in the preview section- @T16bc91af',
    { tags: '@critical' },
    () => {
      cy.login('administrator');

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
      cy.get('[data-testid="media_object[language][]_0-user-input"]')
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
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').contains('Edit').click();

      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Resource description')
        .click();

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
  // Skkipping test due to some erro rs while importing bibliographic data. To be fixed later.
  it.skip(
    'Verify creating item by importing data through bibliographic ID - @T139381b0',
    { tags: '@high' },
    () => {
      const item_title_bibliographic = 'Yellowstone';
      const videoName = 'test_sample.mp4';
      const bibId = '5520382';

      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);

      // Create Item
      cy.intercept('GET', '/media_objects/new?collection_id=*').as(
        'getManageFile'
      );
      cy.get("[data-testid='collection-create-item-btn']")
        .contains('Create An Item')
        .click();
      cy.wait('@getManageFile').its('response.statusCode').should('eq', 302);

      // Upload file
      cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect');
      cy.get("[data-testid='media-object-edit-select-file-btn']")
        .click()
        .selectFile(getFixturePath(videoName));
      cy.get("[data-testid='media-object-edit-upload-btn']").click();
      cy.wait('@fileuploadredirect')
        .its('response.statusCode')
        .should('eq', 200);
      cy.get("[data-testid='media-object-edit-associated-files-block']").should(
        'contain',
        videoName
      );

      // Go to Resource Description
      cy.intercept('GET', '**/edit?step=resource-description').as(
        'resourcedescription'
      );
      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.wait('@resourcedescription')
        .its('response.statusCode')
        .should('eq', 200);

      // Import Bibliographic ID
      cy.get('[data-testid="resource-description-bibliographic-id"]')
        .clear()
        .type(bibId);
      cy.get('button[name="media_object[import_bib_record]"]').click();
      cy.get('body').then(($body) => {
        if (
          $body.find('#media_object_bibliographic_id_confirm_btn').length > 0
        ) {
          cy.get('#media_object_bibliographic_id_confirm_btn').click({
            force: true,
          });
        }
      });

      // Validate imported metadata
      cy.get('[data-testid="resource-description-title"]').should(
        'have.value',
        'Yellowstone'
      );
      cy.get('[data-testid="resource-description-alternative-title"]').should(
        'have.value',
        'Yellowstone National Park'
      );
      cy.get('[data-testid="resource-description-date-issued"]').should(
        'have.value',
        '2003'
      );
      cy.get('[data-testid="resource-description-creator"]')
        .eq(0)
        .should('have.value', 'Vassar, David.');
      cy.get('[data-testid="resource-description-abstract"]')
        .invoke('val')
        .should('include', 'In 1872, Yellowstone National Park');

      const contributors = [
        'Vassar, David.',
        'Mudd, Roger, 1928-2021',
        'Greystone Communications.',
        'History Channel (Television network)',
        'Arts and Entertainment Network.',
        'New Video Group.',
      ];
      contributors.forEach((val, i) => {
        cy.get('[data-testid="resource-description-contributor"]')
          .eq(i)
          .should('have.value', val);
      });

      const publishers = [
        'A & E Television Networks',
        'Distributed in the U.S. by New Video',
      ];
      publishers.forEach((val, i) => {
        cy.get('[data-testid="resource-description-publisher"]')
          .eq(i)
          .should('have.value', val);
      });

      cy.get(
        '[data-testid="resource-description-media-object[language][]"]'
      ).should('have.value', 'English');
      cy.get(
        '[data-testid="resource-description-physical-description"]'
      ).should(
        'have.value',
        '1 videocassette (50 min.) sd., col. with b&w sequences ; 1/2 in.'
      );

      const subjects = [
        'Nature',
        'Effect of human beings on',
        'History',
        'Endangered species',
        'Forest fires',
        'Environmental aspects',
        'Snowmobiles',
        'Environmental conditions',
      ];
      subjects.forEach((val, i) => {
        cy.get('[data-testid="resource-description-topical-subject"]')
          .eq(i)
          .should('have.value', val);
      });

      cy.get('[data-testid="resource-description-geographic-subject"]').should(
        'have.value',
        'Yellowstone National Park'
      );
      cy.get('[data-testid="resource-description-note"]').contains(
        'Originally broadcast as an episode'
      );

      // Structure Page
      cy.intercept('GET', '**/edit?step=structure').as('structurepage');
      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.wait('@structurepage').its('response.statusCode').should('eq', 200);

      // Access Control Page
      cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.wait('@accesspage').its('response.statusCode').should('eq', 200);

      // complete creation
      cy.get('[data-testid="media-object-continue-btn"]').click();

      cy.waitForVideoReady();
      // Validate final display metadata and playback
      cy.get('[data-testid="media-object-title"]').should(
        'contain.text',
        'Yellowstone'
      );
      cy.get('[data-testid="metadata-display"]').within(() => {
        cy.get('dt')
          .contains('Publication date')
          .next('dd')
          .should('have.text', '2003');
        cy.get('dt')
          .contains('Main contributor(s)')
          .next('dd')
          .should('contain.text', 'Vassar, David.');
      });

      cy.url().then((url) => {
        const item_id = url.split('/').pop();
        createdItems.push(item_id);
        cy.log(`Item successfully created with ID: ${item_id}`);
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

    cy.get('[data-testid="media_object[series][]_0-user-input"]')
      .clear()
      .type(series)
      .should('have.value', series);

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
          .find('article.blacklight-mediaobject')
          .each(($article, index) => {
            if (index < 4) {
              cy.wrap($article)
                .find('[data-testid="bookmark-toggle"]')
                .check({ force: true });
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
        .find('.volume-slider-range')
        .should('exist')
        .invoke('val', 70)
        .trigger('input')
        .trigger('change')
        .should(($el) => {
          const value = parseInt($el.val(), 10);
          expect(value).to.be.lessThan(100);
        });

      //validating the volume has changed
      cy.get('[data-testid="waveform-toolbar"]')
        .find('.volume-slider-range')
        .should(($el) => {
          const value = parseInt($el.val(), 10);
          expect(value).to.be.lessThan(100);
        });
      //Add a Heading
      cy.get('[data-testid="add-heading-button"]')
        .contains('Add a Heading')
        .click();
      cy.get('[data-testid="heading-form-title"]').type(heading); //Heading title
      cy.get('[data-testid="heading-form-childof"]').select(item_title); //selecting
      cy.get('[data-testid="heading-form-childof"]')
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

      cy.get('[data-testid="tree-item"]')
        .should('exist')
        .and('have.attr', 'data-label', item_title);

      // Within the section, find the heading
      cy.get('[data-testid="tree-group"]')
        .contains('[data-testid="tree-item"]', heading)
        .should('exist')
        .within(() => {
          cy.contains('[data-testid="tree-item"]', timespan) //nested timespan
            .should('exist')
            .and('be.visible');
        });

      //Clicking on section to check if it plays the right duration
      const expectedTime = '0:10';
      cy.get('[data-testid="tree-item"]').contains(timespan).click();

      // Wait briefly for the player to seek & update
      cy.wait(1000);
      cy.get('.current-time-display')
        .should('be.visible')
        .should('contain.text', expectedTime); //validating it starts from the right duration
    }
  );

  it(
    'Verify that the created structure can be searched - @T5e5fd1da',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      performSearch(heading);
      cy.get('[data-testid="browse-results-list"]').within(() => {
        cy.contains(item_title).should('exist');
      });
      cy.visit('/');
      performSearch(timespan);
      cy.get('[data-testid="browse-results-list"]').within(() => {
        cy.contains(item_title).should('exist');
      });
    }
  );

<<<<<<< HEAD
=======
  it(
    'Verify editing a structure - advanced edit - @Tc91b132e',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click();
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Structure')
        .click();
      cy.get('[data-testid="media-object-edit-structure-btn-0"]').click();
      cy.get('[data-testid="media-object-struct-adv-edit-btn-0"]').click();
      cy.get('.ace_editor').should('exist');
      const xmlString = `<?xml version="1.0"?>
<Item label="Short Documentary.mp3">
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

      cy.window().then((win) => {
        const editor = win.ace?.edit('text_editor_0'); // from div id="text_editor_0"
        expect(editor).to.exist;
        editor.setValue(xmlString, -1); // -1 to move cursor to top after setting
      });

      cy.get('input[type="button"][value="Save and Exit"]').click();
      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      // Validating the resource description
      cy.get('[data-testid="tree-item"]')
        .should('exist')
        .and('have.length.greaterThan', 0);

      // Validate top-level Item label
      cy.get('[data-testid="tree-item"]')
        .first()
        .should('have.attr', 'data-label', 'Short Documentary.mp3');

      //  Validate "Opening" section exists
      cy.get('[data-testid="tree-item"][data-label="Opening"]').should('exist');

      // Validate Intro 1 and Intro 2 under "Opening"
      cy.get('[data-testid="tree-item"][data-label="Intro 1"]').should('exist');
      cy.get('[data-testid="tree-item"][data-label="Intro 2"]').should('exist');

      // Validate "Main Content" section exists
      cy.get('[data-testid="tree-item"][data-label="Main Content"]').should(
        'exist'
      );

      // Validate Segment A and Segment B under "Main Content"
      cy.get('[data-testid="tree-item"][data-label="Segment A"]').should(
        'exist'
      );
      cy.get('[data-testid="tree-item"][data-label="Segment B"]').should(
        'exist'
      );

      // Validate final timespan "Wrap-up" at top level
      cy.get('[data-testid="tree-item"][data-label="Wrap-up"]').should('exist');
    }
  );
  it(
    'Verify editing a structure - advanced edit - @Tc91b132e',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click();
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Structure')
        .click(); //structure page
      cy.get('[data-testid="media-object-edit-structure-btn-0"]').click();
      //Remove the previous structure
      cy.get('[data-testid="media-object-remove-structure-btn"]').click();
      cy.get('[data-testid="table-view-delete-confirmation-btn"]').click();
      //click on upload
      cy.get('[data-testid="media-object-edit-structure-btn-0"]').click();
      //cy.get('[data-testid="media-object-struct-upload-btn-0"]').click();

      // Ensure file input is present
      cy.readFile(getFixturePath('test-sample.mp4.structure.xml'), null).then(
        (contents) => {
          cy.get('input[name="master_file[structure]"]').selectFile(
            {
              contents,
              fileName: 'test-sample.mp4.structure.xml',
              mimeType: 'text/xml',
            },
            { force: true }
          );
        }
      );

      cy.wait(6000);

      cy.get('[data-testid="media-object-continue-btn"]').click();
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      // Validating the resource description
      cy.get('[data-testid="tree-item"]')
        .should('exist')
        .and('have.length.greaterThan', 0);

      // Validate top-level Item label
      cy.get('[data-testid="tree-item"]')
        .first()
        .should('have.attr', 'data-label', 'Documentary.mp3');

      cy.get('[data-testid="tree-item"][data-label="Starting act"]').should(
        'exist'
      );

      cy.get('[data-testid="tree-item"][data-label="Part 1"]').should('exist');
      cy.get('[data-testid="tree-item"][data-label="Part 2"]').should('exist');

      cy.get('[data-testid="tree-item"][data-label="Body"]').should('exist');

      cy.get('[data-testid="tree-item"][data-label="Content 1"]').should(
        'exist'
      );
      cy.get('[data-testid="tree-item"][data-label="Content 2"]').should(
        'exist'
      );

      cy.get('[data-testid="tree-item"][data-label="The end"]').should('exist');
    }
  );

>>>>>>> f14def94b (Unit test cases)
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
      getFixturePath(captionFileName),
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
    'Verify marking closed captions [cc] as a transcript',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Manage files')
        .click();
      cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();
      cy.get('[data-testid="media-object-supplemenatl-file-edit-btn"]').click();
      cy.get(
        '[data-testid="media-object-treat-as-transcript-checkbox"]'
      ).click();
      cy.get('[data-testid="media-object-supplemental-file-save-btn"]').click();
      cy.get('[data-testid="media-object-continue-btn"]').click();

      //Verifying on ramp video
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      //Verify that transcripts tab is present
      cy.get('[data-testid="media-object-tab-transcripts"]').click();

      //Downloading the captions file
      cy.get('[data-testid="media-object-tab-files"]').click();
      cy.get('[data-testid="supplemental-files-display-content"]')
        .contains('captions-example.srt')
        .should('have.attr', 'href')
        .then((href) => {
          expect(href).to.include('/supplemental_files/');
          // optionally visit or request to confirm it's downloadable
          cy.request(href).then((response) => {
            expect(response.status).to.eq(200);
            expect(response.headers['content-type']).to.include('text/srt');
            expect(response.body).to.contain('1');
          });
        });

      // verifying the browse page
      homePage.getBrowseNavButton().click();
      cy.contains('button', 'Has Transcripts').click();
      cy.contains('#facet-has_transcripts_bsi .facet-select', 'Yes').click();
      cy.contains('button', 'Has Captions').click();
      cy.contains('#facet-has_captions_bsi .facet-select', 'Yes').click();
      cy.get(`[data-testid="browse-document-title-${item_id}"]`)
        .should('exist')
        .and('contain.text', 'Automation Item title');

      //searching the caption line and checking if we get results
      performSearch('Hiring a transcriber saves time and resources.');
      cy.get(`[data-testid="browse-document-title-${item_id}"]`)
        .should('exist')
        .and('contain.text', 'Automation Item title');
      cy.get('[data-testid="browse-value-found-in"]')
        .should('exist')
        .and('contain.text', 'transcript');
    }
  );

  it(
    'Verify removing the closed captions [cc] in a section file',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Manage files')
        .click();
      cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();
      cy.get(
        '[data-testid="media-object-supplemenatl-file-delete-btn"]'
      ).click();
      cy.get('[data-testid="table-view-delete-confirmation-btn"]').click();

      //Verifying on ramp video
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      //Verify that transcripts tab should not exist from the above test case
      cy.get('[data-testid="media-object-tab-transcripts"]').should(
        'not.exist'
      );

      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();

      cy.get('.vjs-big-play-button').should('exist').click();

      // Ensure CC button is not visible or rendered
      cy.get('[data-testid="media-player"]').within(() => {
        cy.get('button.vjs-subs-caps-button').should('not.exist');
        cy.get('.vjs-text-track-cue-eng').should('not.exist');
      });
    }
  );
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
      ).selectFile(getFixturePath(transcriptFileName), {
        force: true,
      });
      cy.get('[data-testid="alert"]').contains(
        'Supplemental file successfully added.'
      );

      //Verifying on ramp video
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();

      // Click transcript tab
      cy.get('[data-testid="media-object-tab-transcripts"]').click();

      // Ensure the video is initialized and playing
      cy.get('button[title="Play"]').click();
      cy.wait(1000); // Allow time for video to start

      // clicking on a specific time - 28 seconds
      const transcriptTime = '[00:00:28]';
      const expectedSeconds = 3;

      cy.get('[data-testid="transcript_time"]')
        .contains(transcriptTime)
        .should('exist')
        .should('be.visible')
        .scrollIntoView()
        .parents('[data-testid="transcript_item"]')
        .should('exist')
        .click();

      cy.wait(2000); // allow player to seek

      cy.get('video')
        .should('exist')
        .should('have.prop', 'currentTime')
        .then((currentTime) => {
          expect(currentTime).to.be.closeTo(expectedSeconds, 3);
        });
    }
  );

  it('Verify downloading a transcript ', { tags: '@high' }, () => {
    cy.login('administrator');
    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();
    //Downloading the transcript file
    cy.get('[data-testid="media-object-tab-transcripts"]').click();

    cy.get('[data-testid="transcript-downloader"]').click();

    cy.readFile(getDownloadPath('transcript-example.vtt'), { timeout: 15000 })
      .should('exist')
      .and('contain', 'WEBVTT');
  });

  it(
    'Verify removing a transcript in a section file',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Manage files')
        .click();
      cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();
      cy.get(
        '[data-testid="media-object-supplemenatl-file-delete-btn"]'
      ).click();
      cy.get('[data-testid="table-view-delete-confirmation-btn"]').click();

      //Verifying on ramp video
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();

      // Transcript and files tab shoudl not exits because there are no other files too
      cy.get('[data-testid="media-object-tab-transcripts"]').should(
        'not.exist'
      );
      cy.get('[data-testid="media-object-tab-files"]').should('not.exist');
    }
  );

  it(
    'Verify adding Section Supplemental Files to a section file ',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Manage files')
        .click();
      cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();

      const sectionSupplementalFileName = 'example.json';
      //added force: true because the element is not visible
      cy.get('[data-testid="media-object-upload-button-supplemental"]')
        .first()
        .selectFile(getFixturePath(sectionSupplementalFileName), {
          force: true,
        });
      cy.get('[data-testid="media-object-continue-btn"]').click();

      //Verifying on ramp video
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();

      cy.get('[data-testid="media-object-tab-files"]').click();

      cy.get('[data-testid="supplemental-files-display-content"]')
        .find('a')
        .contains(sectionSupplementalFileName)
        .should('have.attr', 'href')
        .should('exist');
      // Click the link to trigger download

      // Wait for file to appear in downloads folder and verify contents
      //commented out because click for download does not exist
      // cy.readFile(getDownloadPath(sectionSupplementalFileName)).should('exist');
    }
  );
  it(
    'Verify removing Section Supplemental Files from a section file',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();
      cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
      cy.get('[data-testid="media-object-side-nav-link"]')
        .contains('Manage files')
        .click();
      cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();
      cy.get(
        '[data-testid="media-object-supplemenatl-file-delete-btn"]'
      ).click();
      cy.get('[data-testid="table-view-delete-confirmation-btn"]').click();

      //Verifying on ramp video
      cy.visit('/media_objects/' + item_id);
      cy.waitForVideoReady();

      // Transcript and files tab shoudl not exits because there are no other files too
      cy.get('[data-testid="media-object-tab-files"]').should('not.exist');
    }
  );

  it('Verify adding item supplemental files ', { tags: '@high' }, () => {
    cy.login('administrator');
    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();
    cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
    cy.get('[data-testid="media-object-side-nav-link"]')
      .contains('Manage files')
      .click();

    const sectionSupplementalFileName = 'image.png';

    cy.get('[data-testid="media-object-upload-button-supplemental"]')
      .eq(1)
      .selectFile(getFixturePath(sectionSupplementalFileName), {
        force: true,
      });
    cy.get('[data-testid="media-object-continue-btn"]').click();

    //Verifying on ramp video
    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();

    cy.get('[data-testid="media-object-tab-files"]').click();

    cy.get('[data-testid="supplemental-files-display-content"]')
      .find('a')
      .contains(sectionSupplementalFileName)
      .should('exist'); // image is uploaded

    // Wait for file to appear in downloads folder and verify contents
    // //commented out because click for download does not exist
    //cy.readFile(getDownloadPath(sectionSupplementalFileName)).should('exist');
  });

  it('Verify removing item supplemental files ', { tags: '@high' }, () => {
    cy.login('administrator');
    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();
    cy.get('[data-testid="media-object-edit-btn"]').click(); //edit button
    cy.get('[data-testid="media-object-side-nav-link"]')
      .contains('Manage files')
      .click();
    cy.get('[data-testid="media-object-supplemenatl-file-delete-btn"]').click();
    cy.get('[data-testid="table-view-delete-confirmation-btn"]').click();

    //Verifying on ramp video
    cy.visit('/media_objects/' + item_id);
    cy.waitForVideoReady();

    // Transcript and files tab shoudl not exits because there are no other files too
    cy.get('[data-testid="media-object-tab-files"]').should('not.exist');
  });

  //This case and thus the following case may fail intermittently since the item sometimes takes too long to load,
  //and the timeline button is disabled
  it(
    'Verify if a user is able to create timelines under an item - @T9972f970 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');
      cy.visit('/media_objects/' + item_id);

      cy.intercept('POST', '/timelines').as('createTimeline');

      cy.contains('Create Timeline').click();
      cy.get('[data-testid="media-object-modal-create-timeline-btn"]').click();
      cy.wait('@createTimeline').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
      });
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
      //Changing the default timeline title to a custom title for later search and validation.
      //iiif‑timeliner bundlle so cannot add data-testid, using ids for now
      cy.contains('h3', 'Documentary.mp3').should('be.visible').click();
      cy.get('#manifestLabel')
        .clear()
        .type(item_title)
        .should('have.value', item_title);
      cy.contains('button', 'Save').should('be.visible').click();
      cy.get('button[title="Save timeline"]').should('be.visible').click();
      cy.get('#alert-dialog-slide-title').should(
        'contain.text',
        'Saved Successfully.'
      );
    }
  );

  it(
    'Verify timeline playback by visiting timeliner directly ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/timelines');

      cy.get('[data-testid="users-search-field"]')
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
    cy.get('[data-testid="users-search-field"]')
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
