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
  const collectionPage = new CollectionPage();
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
        "Cannot read properties of undefined (reading 'success')"
      ) ||
      err.message.includes(
        "Cannot read properties of undefined (reading 'times')"
      )
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
      { setPublicAccess: false }
    );

    // Navigate to the collection and create complex media object
    collectionPage.navigateToCollection(collection_title);

    collectionPage.createItem(media_object_title, {
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

    // Then delete the collection
    collectionPage.deleteCollectionByName(collection_title);
    collectionPage.deleteCollectionByName(new_collection_title);
    // Delete unit
    UnitPage.deleteUnitByName(unit_title);
  });
});

it('Verify the user is able to update Access Control for all selected items - Special Access - Avalon User - @T64227f02', () => {
  // Select the created media object
  cy.login('administrator');
  homePage.getBrowseNavButton().click();
  performSearch(media_object_title);
  cy.get('[data-testid="bookmark-toggle"]').first().click({ force: true });
  cy.visit(`/bookmarks`);
  cy.get('a[href="/bookmarks/update_access_control"]').click();
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
  cy.get('[data-testid="alert"]')
    .should('be.visible')
    .and('contain', 'Access controls are being updated on 1 item.');

  // Verify that user@example.com has access to the media object
  homePage.logout();
  //Login as a user who is not a staff to collection to validate the result
  cy.login('user');
  cy.visit('/');
  cy.intercept('GET', '/media_objects/*').as('getmediaobject');
  cy.visit('/media_objects/' + media_object_id);
  cy.wait('@getmediaobject').then((interception) => {
    expect(interception.response.statusCode).to.eq(200);
  });
});

it('Verify that the users without permission to update access control is not able to update Access Control from selected items- @@Tea7101fb', () => {
  cy.login('user');
  // Select the media object for which the access was given in previous test
  homePage.getBrowseNavButton().click();
  performSearch(media_object_title);
  cy.get('[data-testid="bookmark-toggle"]').first().click({ force: true });
  //Verify the count has increased to 1
  cy.get('a[href="/bookmarks"]')
    .find('[data-testid="bookmark-counter"]')
    .should('have.text', '1');
  cy.visit(`/bookmarks`);
  // Verify that the Update Access Control button is not visible
  cy.get('a[href="/bookmarks/update_access_control"]').should('not.exist');
});

it('Verify if the user is able to move items to a new collection- @@T8b339069', () => {
  cy.login('administrator');
  // Create a new collection to move the item into
  navigateToManageContent();
  collectionPage.createCollection(
    { title: new_collection_title },
    { setPublicAccess: false }
  );
  //
  cy.visit(`/bookmarks`);
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
  //Select the new collection and move
  cy.get('[data-testid="bookmark-collection-dropdown"] option')
    .contains(new_collection_title)
    .should('exist');

  cy.get('[data-testid="bookmark-collection-dropdown"]').select(
    new_collection_title,
    { force: true }
  );
  cy.get('[data-testid="bookmark-move"]').click();
  // The alert
  cy.get('[data-testid="alert"]')
    .should('be.visible')
    .and(
      'contain',
      `One item is being moved to collection ${new_collection_title}.`
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
it('Verify if the user is able to publish items - @Tfd4e6b7b', () => {
  cy.login('administrator');
  cy.visit(`/bookmarks`);
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
  cy.get('[data-testid="alert"]')
    .should('be.visible')
    .and('contain', 'One item is being published.');
  //Verify that the item is published by visiting the media object page
  cy.visit('/media_objects/' + media_object_id);
  // Verify that the Unpublish button is visible
  cy.get('[data-testid="media-object-unpublish-btn"]')
    .should('be.visible')
    .and('have.text', 'Unpublish');
});
it('Verify users without permission is not able to publish items from selected items - @T520b6f98', () => {
  cy.login('user');
  // Select the media object for which the access was given in previous test
  cy.visit(`/bookmarks`);
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
  cy.visit(`/bookmarks`);
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
  // Select the media object for which the access was given in previous test
  cy.visit(`/bookmarks`);
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
  cy.get(`[data-testid="browse-document-title-${media_object_id}"]`)
    .closest('article')
    .find('[data-testid="bookmark-toggle"]')
    .first()
    .uncheck({ force: true });
  //Refresh the page and verify the item is removed from the list
  cy.visit(`/bookmarks`);
  cy.get(`[data-testid="browse-document-title-${media_object_id}"]`).should(
    'not.be.visible'
  );
});

it('Verify if the user is able to merge items - @Tb96ea8d8', () => {
  cy.login('administrator');
  // Select the media object for which the access was given in previous test
  cy.visit(`/bookmarks`);
  // Create an item to merge with the existing item
  // Navigate to the collection and create complex media object
  collectionPage.navigateToCollection(new_collection_title);

  collectionPage.createItem(new_media_object_title, {
    publish: true,
    addStructure: true,
  });

  // Get the media object ID from the alias
  cy.get('@mediaObjectId').then((id) => {
    new_media_object_id = id;
  });
  // Select the new media object
  homePage.getBrowseNavButton().click();
  performSearch(media_object_title);
  cy.get('[data-testid="bookmark-toggle"]').first().click({ force: true });
  cy.visit(`/bookmarks`);
  cy.get('a[href="/bookmarks/update_access_control"]').click();
  //check that the item is checked on bookmarks page
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
  //Check both items are selected
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
  //Click on Merge and merge the second item into the first item
  cy.get('a[href="/bookmarks/merge"]').click();
  cy.get(`[data-testid="merge-media-object-${media_object_id}"]`).click({
    force: true,
  });
  //Verify the alert for merging
  cy.get('[data-testid="alert"]')
    .should('be.visible')
    .and('contain', 'Merging 1 items into')
    .and('contain', media_object_title);
  //Visit the first media object page to verify the merged content
  cy.visit('/media_objects/' + media_object_id);
  cy.get('[data-testid="tree-item"]').should('have.length', 2);
  //The second media object should no longer be accessible
  cy.intercept('GET', '/media_objects/*').as('getmediaobject');
  cy.visit('/media_objects/' + new_media_object_id);
  cy.wait('@getmediaobject').then((interception) => {
    expect(interception.response.statusCode).to.eq(410);
  });
  cy.get('h2').first().should('have.text', 'Item Deleted');
  cy.get('p')
    .eq(0)
    .should(
      'have.text',
      'The item you requested has been deleted from the system. If this is not expected, contact your support staff.'
    );
});
it('Verify if the user is able to delete items - @T47a94cdc', () => {
  cy.login('administrator');
  // Verify the media object is selected to be deleted
  cy.visit(`/bookmarks`);
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
  cy.get('a[href="/bookmarks/delete"]').click();
  //confirm delete
  cy.contains('button', 'Yes, I am Sure').click();
  // The alert
  cy.get('[data-testid="alert"]')
    .should('be.visible')
    .and('contain', 'One item is being deleted.');
  // Verify that the item is deleted by visiting the media object page
  cy.intercept('GET', '/media_objects/*').as('getmediaobject');
  cy.visit('/media_objects/' + media_object_id);
  cy.wait('@getmediaobject').then((interception) => {
    expect(interception.response.statusCode).to.eq(410);
  });
  cy.get('h2').first().should('have.text', 'Item Deleted');
  cy.get('p')
    .eq(0)
    .should(
      'have.text',
      'The item you requested has been deleted from the system. If this is not expected, contact your support staff.'
    );
});

it('Verify bulk action buttons are disabled and re-enabled when selection changes', () => {
  cy.login('administrator');
  cy.visit('/bookmarks');

  // Deselect all items
  cy.get('#bookmarks_selectall').uncheck({ force: true });

  // Verify buttons are disabled
  cy.get('.bulk-actions a').first().should('have.class', 'disabled');

  // Select all items again
  cy.get('#bookmarks_selectall').check({ force: true });

  // Verify buttons are enabled
  cy.get('.bulk-actions a').each(($btn) => {
    cy.wrap($btn).should('not.have.class', 'disabled');
    cy.wrap($btn).should('not.have.attr', 'aria-disabled', 'true');
  });
});

it('Verify selection count is displayed when items are selected', () => {
  cy.login('administrator');
  cy.visit('/bookmarks');

  // Verify selection count is displayed
  cy.get('#selection-count').should('be.visible').and('contain', 'selected');
});

it('Verify selection count is hidden when no items are selected', () => {
  cy.login('administrator');
  cy.visit('/bookmarks');

  // Deselect all items
  cy.get('#bookmarks_selectall').uncheck({ force: true });

  // Verify selection count is hidden
  cy.get('#selection-count').should('have.class', 'd-none');
});
