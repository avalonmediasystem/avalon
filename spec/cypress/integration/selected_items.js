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
import HomePage from '../pageObjects/homePage';
const homePage = new HomePage();
import {
  navigateToManageContent,
  selectLoggedInUsersOnlyAccess,
  performSearch,
} from '../support/navigation';
import UnitPage from '../pageObjects/unitPage.js';
const unitPage = UnitPage;

const collectionPage = new CollectionPage();

context('Selected Items', () => {
  var unit_title = `Automation unit title ${
    Math.floor(Math.random() * 10000) + 1
  }`;

  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  const new_collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var media_object_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;
  var new_media_object_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;
  var media_object_id;
  var new_media_object_id;

  Cypress.on('uncaught:exception', (err, runnable) => {
    if (
      err.message.includes(
        "Cannot read properties of undefined (reading 'success')",
      ) ||
      err.message.includes(
        "Cannot read properties of undefined (reading 'times')",
      )
    ) {
      return false;
    }
  });

  // Create collection and complex media object before all tests
  before(() => {
    // Clear any existing selected items for administrator
    cy.login('administrator');
    cy.visit('/bookmarks');
    cy.get('body').then(($body) => {
      if (
        $body.find(
          '.alert.alert-info:contains("You have not selected any items")',
        ).length === 0
      ) {
        cy.get('.bookmark-selection').check({ force: true });
        cy.on('window:confirm', () => true);
        cy.get('[data-testid="remove-selected-btn"]').click({ force: true });
        cy.get('.alert.alert-info').should(
          'contain',
          'You have not selected any items',
        );
      }
    });

    // Clear any existing selected items for user
    cy.login('user');
    cy.visit('/bookmarks');
    cy.get('body').then(($body) => {
      if (
        $body.find(
          '.alert.alert-info:contains("You have not selected any items")',
        ).length === 0
      ) {
        cy.get('.bookmark-selection').check({ force: true });
        cy.on('window:confirm', () => true);
        cy.get('[data-testid="remove-selected-btn"]').click({ force: true });
        cy.get('.alert.alert-info').should(
          'contain',
          'You have not selected any items',
        );
      }
    });

    cy.login('administrator');
    unitPage.createUnit({ title: unit_title });
    navigateToManageContent();

    // Create collection with public access
    collectionPage.createCollection(
      { title: collection_title, unitName: unit_title },
      { setPublicAccess: false },
    );

    // Navigate to the collection and create media object
    collectionPage.navigateToCollection(collection_title);

    collectionPage
      .createItem(media_object_title, 'test_sample.mp4')
      .then((id) => {
        media_object_id = id;
      });
  });

  // Clean up after all tests - ITEM FIRST, THEN COLLECTION
  after(() => {
    cy.login('administrator');

    // Then delete the collection
    collectionPage.deleteCollectionByName(collection_title);
    collectionPage.deleteCollectionByName(new_collection_title);
    // Delete unit
    UnitPage.deleteUnitByName(unit_title);
  });

  it('Verify if the user is able to publish items - @Tfd4e6b7b', () => {
    homePage.getBrowseNavButton().click();
    performSearch(media_object_title);
    cy.get('[data-testid="bookmark-toggle"]').first().click({ force: true });
    cy.visit('/bookmarks');
    cy.visit('/bookmarks');
    //check that the item is checked on bookmarks page
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
      .closest('article')
      .find('[data-testid="bookmark-toggle"]')
      .first()
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      })
      .should('be.checked');
    //Click on Publish button for user to access the item
    cy.get('a[href="/bookmarks/publish"]').click();
    //Verify the alert for publishing
    cy.get('[data-testid="alert"]', { timeout: 10000 })
      .should('be.visible')
      .and('contain', 'One item is being published.');
    //Verify that the item is published by visiting the media object page
    cy.wait(2000); // wait for the publish action to complete
    cy.visit('/media_objects/' + media_object_id);
    // Verify that the Unpublish button is visible
    cy.get('[data-testid="media-object-unpublish-btn"]')
      .should('be.visible')
      .and('have.text', 'Unpublish');
  });

  it('Verify the user is able to update Access Control for all selected items - Special Access - Avalon User - @T64227f02', () => {
    // Select the created media object
    cy.login('administrator');
    cy.visit('/bookmarks');
    cy.visit('/bookmarks');
    //check that the item is checked on bookmarks page
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
      .closest('article')
      .find('[data-testid="bookmark-toggle"]')
      .first()
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      })
      .should('be.checked');

    // Open Update Access Control modal
    cy.get('a[href="/bookmarks/update_access_control"]').click();
    cy.get('.modal-content', { timeout: 10000 }).should('be.visible');

    // Update Access Control to Special Access - Avalon User
    cy.get('[data-testid="user-user-input"]').clear().type('user@example.com');

    // click the matching suggestion
    cy.get('[data-testid="user-popup"]')
      .should('be.visible')
      .contains('li', 'user@example.com')
      .click();
    //click on add button
    cy.get('[data-testid="bookmark-add-user"]').click();

    // Expect success alert
    cy.get('[data-testid="alert"]', { timeout: 10000 })
      .should('be.visible')
      .and('contain', 'Access controls are being updated on 1 item.');
    cy.wait(6000); // wait for logout to complete
    // Verify that user@example.com has access to the media object
    homePage.logout();

    //Login as a user who is not a staff to collection to validate the result
    cy.login('user');
    cy.reload();
    // Use failOnStatusCode false in case access is still propagating
    cy.visit('/media_objects/' + media_object_id, { failOnStatusCode: false });
    // Verify we can see the page (not a 401 redirect)
    cy.get('[data-testid="media-object-title"]', { timeout: 10000 })
      .should('be.visible')
      .and('contain', media_object_title);
  });

  it('Verify that the users without permission to update access control is not able to update Access Control from selected items - @Tea7101fb', () => {
    cy.login('user');
    // Select the media object for which the access was given in previous test
    homePage.getBrowseNavButton().click();
    performSearch(media_object_title);
    cy.get('[data-testid="bookmark-toggle"]').first().click({ force: true });
    cy.reload();

    // Verify the count has increased to at least 1
    cy.get('[data-testid="bookmark-counter"]')
      .invoke('text')
      .then((text) => {
        expect(parseInt(text)).to.be.gte(1);
      });
    cy.visit('/bookmarks');
    // Verify that the Update Access Control button is not visible
    cy.get('a[href="/bookmarks/update_access_control"]').should('not.exist');
  });

  it('Verify if the user is able to move items to a new collection - @T8b339069', () => {
    cy.login('administrator');
    // Create a new collection to move the item into
    navigateToManageContent();
    collectionPage.createCollection(
      { title: new_collection_title, unitName: unit_title },
      { setPublicAccess: false },
    );
    cy.visit('/bookmarks');
    //check that the item is checked on bookmarks page
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
      .closest('article')
      .find('[data-testid="bookmark-toggle"]')
      .first()
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      })
      .should('be.checked');
    //Click on Move
    cy.get('a[href="/bookmarks/move"]').click();
    cy.get('.modal-content', { timeout: 10000 }).should('be.visible');
    //Select the new collection and move
    cy.get('[data-testid="bookmark-collection-dropdown"] option')
      .contains(new_collection_title)
      .should('exist');

    cy.get('[data-testid="bookmark-collection-dropdown"]').select(
      new_collection_title,
      { force: true },
    );
    cy.get('[data-testid="bookmark-move"]').click();
    // The alert
    cy.get('[data-testid="alert"]', { timeout: 10000 })
      .should('be.visible')
      .and(
        'contain',
        `One item is being moved to collection ${new_collection_title}.`,
      );
    // Verify that the item is now in the new collection
    collectionPage.navigateToCollection(new_collection_title);
    //Click on List All Items
    cy.get('[data-testid="collection-list-all-item-btn"]').click();
    // Verify the media object is present in the new collection
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
      .should('be.visible')
      .and('contain', media_object_title);
  });

  it('Verify users without permission is not able to publish items from selected items - @T520b6f98', () => {
    cy.login('user');
    // Select the media object for which the access was given in previous test
    cy.visit('/bookmarks');
    performSearch(media_object_title);
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
      .closest('article')
      .find('[data-testid="bookmark-toggle"]')
      .first()
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      })
      .should('be.checked');
    // Verify that the Publish and Unpublish is not visible
    cy.get('a[href="/bookmarks/publish"]').should('not.exist');
    cy.get('a[href="/bookmarks/unpublish"]').should('not.exist');
  });

  it('Verify users without permission is not able to delete items from selected items - @Tbe94df87', () => {
    cy.login('user');
    // Select the media object for which the access was given in previous test
    cy.visit('/bookmarks');
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
      .closest('article')
      .find('[data-testid="bookmark-toggle"]')
      .first()
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      })
      .should('be.checked');
    // Verify that the Delete button is not visible
    cy.get('a[href="/bookmarks/delete"]').should('not.exist');
  });

  it('Verify removing items from selected items list - @Td13db335', () => {
    cy.login('user');
    cy.visit('/bookmarks');

    // Ensure item is selected
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
      .closest('article')
      .find('[data-testid="bookmark-toggle"]')
      .first()
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      })
      .should('be.checked');

    // Click Clear selected items and accept the confirm dialog
    cy.on('window:confirm', () => true);
    cy.get('[data-testid="remove-selected-btn"]').click();

    // Verify success alert
    cy.get('[data-testid="alert"]', { timeout: 10000 })
      .should('be.visible')
      .and('contain', 'Cleared 1 item from your selections.');

    // Verify no items remain
    cy.get('.alert.alert-info')
      .should('be.visible')
      .and('contain', 'You have not selected any items');

    // Verify the item is gone from the list
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`).should(
      'not.exist',
    );

    // Verify the counter has decreased to 0
    cy.get('[data-testid="bookmark-counter"]').should('have.text', '0');
  });

  it('Verify if the user is able to merge items - @Tb96ea8d8', () => {
    cy.login('administrator');
    // Create an item to merge with the existing item
    collectionPage.navigateToCollection(new_collection_title);

    collectionPage
      .createItem(new_media_object_title, 'test_sample.mp4')
      .then((id) => {
        new_media_object_id = id;

        // Bookmark both items
        homePage.getBrowseNavButton().click();
        performSearch(media_object_title);
        cy.get('[data-testid="bookmark-toggle"]')
          .first()
          .then(($cb) => {
            if (!$cb.prop('checked')) {
              cy.wrap($cb).check({ force: true });
            }
          });

        homePage.getBrowseNavButton().click();
        performSearch(new_media_object_title);
        cy.get('[data-testid="bookmark-toggle"]')
          .first()
          .then(($cb) => {
            if (!$cb.prop('checked')) {
              cy.wrap($cb).check({ force: true });
            }
          });

        cy.visit('/bookmarks');

        // Check both items are selected
        cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
          .closest('article')
          .find('[data-testid="bookmark-toggle"]')
          .first()
          .then(($cb) => {
            if (!$cb.prop('checked')) {
              cy.wrap($cb).check({ force: true });
            }
          })
          .should('be.checked');

        cy.get(`[data-testid="browse-document-title-${new_media_object_id}"]`)
          .closest('article')
          .find('[data-testid="bookmark-toggle"]')
          .first()
          .then(($cb) => {
            if (!$cb.prop('checked')) {
              cy.wrap($cb).check({ force: true });
            }
          })
          .should('be.checked');

        // Click on Merge and merge the second item into the first item
        cy.get('a[href="/bookmarks/merge"]').click();
        cy.get('.modal-content', { timeout: 10000 }).should('be.visible');

        cy.get(`[data-testid="merge-media-object-${media_object_id}"]`).click({
          force: true,
        });

        // Submit merge
        cy.contains('button', 'Merge').click();

        // Verify the alert for merging
        cy.get('[data-testid="alert"]', { timeout: 10000 })
          .should('be.visible')
          .and('contain', 'Merging 1 items into')
          .and('contain', media_object_title);
        cy.wait(3000); // wait for merge to complete
        // Visit the first media object page to verify the merged content
        cy.visit('/media_objects/' + media_object_id);
        cy.get('[data-testid="tree-item"]').should('have.length', 2);

        // The second media object should no longer be accessible
        cy.intercept('GET', '/media_objects/*').as('getmediaobject');
        cy.visit('/media_objects/' + new_media_object_id, {
          failOnStatusCode: false,
        });
        cy.wait('@getmediaobject').then((interception) => {
          expect(interception.response.statusCode).to.eq(410);
        });
        cy.get('h2').first().should('have.text', 'Item Deleted');
      });
  });

  //fix this
  it('Verify if the user is able to delete items - @T47a94cdc', () => {
    cy.login('administrator');
    // Verify the media object is selected to be deleted
    cy.visit('/bookmarks');
    cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
      .closest('article')
      .find('[data-testid="bookmark-toggle"]')
      .first()
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      })
      .should('be.checked');

    // Open Delete modal
    cy.get('a[href="/bookmarks/delete"]').click();
    cy.get('.modal-content', { timeout: 10000 }).should('be.visible');

    //confirm delete
    cy.contains('button', 'Yes, I am Sure').click();
    // The alert
    cy.get('[data-testid="alert"]', { timeout: 10000 })
      .should('be.visible')
      .and('contain', 'One item is being deleted.');
    // Verify that the item is deleted by visiting the media object page
    cy.wait(2000); // wait for delete action to complete

    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + media_object_id, {
      failOnStatusCode: false,
    });
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(410);
    });
    cy.get('h2').first().should('have.text', 'Item Deleted');
  });

  it('Verify selection count is displayed when items are selected', () => {
    cy.login('administrator');

    // Bookmark first two items from browse page
    homePage.getBrowseNavButton().click();
    cy.get('[data-testid="bookmark-toggle"]')
      .eq(0)
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      });
    cy.get('[data-testid="bookmark-toggle"]')
      .eq(1)
      .then(($cb) => {
        if (!$cb.prop('checked')) {
          cy.wrap($cb).check({ force: true });
        }
      });

    cy.visit('/bookmarks');
    cy.reload();
    // Verify selection count shows 2 selected
    cy.get('[data-testid="selection-count"]')
      .should('be.visible')
      .and('contain', '2 selected');
  });

  it('Verify bulk action buttons are disabled and re-enabled when selection changes', () => {
    cy.login('administrator');
    cy.visit('/bookmarks');

    // Deselect all items
    cy.get('[data-testid="bookmarks-select-all"]').uncheck({ force: true });

    // Verify buttons are disabled
    cy.get('.bulk-actions a').first().should('have.class', 'disabled');

    // Select all items again
    cy.get('[data-testid="bookmarks-select-all"]').check({ force: true });

    // Verify buttons are enabled
    cy.get('.bulk-actions a').each(($btn) => {
      cy.wrap($btn).should('not.have.class', 'disabled');
      cy.wrap($btn).should('not.have.attr', 'aria-disabled', 'true');
    });
  });

  it('Verify selection count is hidden when no items are selected', () => {
    cy.login('administrator');
    cy.visit('/bookmarks');

    // Deselect all items
    cy.get('[data-testid="bookmarks-select-all"]').uncheck({ force: true });

    // Verify selection count is hidden
    cy.get('[data-testid="selection-count"]').should('have.class', 'd-none');
  });
});
