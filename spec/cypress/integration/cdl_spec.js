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

import { navigateToManageContent } from '../support/navigation';
import CollectionPage from '../pageObjects/collectionPage';
import HomePage from '../pageObjects/homePage';
const homePage = new HomePage();
import {
  navigateToManageContent,
  selectLoggedInUsersOnlyAccess,
  performSearch,
} from '../support/navigation';

context('Selected Items', () => {
  const collectionPage = new CollectionPage();

  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var media_object_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;
  var media_object_id;

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
    // Delete the media object first (if it exists)
    if (media_object_id) {
      collectionPage.deleteItemById(media_object_id);
    }

    // Then delete the collection
    collectionPage.deleteCollectionByName(collection_title);
  });
});
it('Verify that the checkouts menu option does not display if CDL is not enabled for Avalon - @Tf7bf6b9a', () => {
  cy.login('administrator');
  // Checkout option does not exist
  cy.get('a[href="/checkouts"]').should('not.exist');
  // Navigate to collection page and verify cdl option does not exist
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="collection-enable-cdl-card"]').should('not.exist');
  cy.get('[data-testid="collection-item-lending-period-card"]').should(
    'not.exist'
  );
});
it('Verify CDL is enabled - @T3c2f5e2e', () => {
  cy.login('administrator');
  // Checkout option exists
  cy.get('a[href="/checkouts"]').should('exist').and('be.visible');
  // Navigate to collection page and verify CDL controls exist
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="collection-enable-cdl-card"]')
    .should('exist')
    .and('be.visible');
  cy.get('[data-testid="collection-item-lending-period-card"]')
    .should('exist')
    .and('be.visible');
});

it('Enable CDL for a collection and borrow an item- @T3c2f5e2e', () => {
  cy.login('administrator');
  // Checkout option exists
  cy.get('a[href="/checkouts"]').should('exist').and('be.visible');
  // Navigate to collection page and verify CDL controls exist
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="cdl-enable-checkbox"]').click({ force: true });
  cy.get('[data-testid="cdl-save-setting"]').click();
  cy.visit('/media_objects/' + media_object_id);
  // verify the borrow gate text is shown
  cy.get('.checkout .centered.video')
    .should('be.visible')
    .within(() => {
      cy.contains('p', 'Borrow this item to access media resources.').should(
        'be.visible'
      );

      // verify the borrow button
      cy.get('input[type="submit"][value="Borrow for 14 days"]').should(
        'be.visible'
      );
    });
  //Click on borrow button and verify the media player is shown
  cy.get('input[type="submit"][value="Borrow for 14 days"]').click();
  cy.get('button[title="Play Video"]')
    .should('be.visible')
    .and('contain', 'Play Video');
  cy.contains('Details').should('be.visible');
  cy.contains('Sections').should('be.visible');
  cy.get('[data-testid="media-object-return-now-btn"]').should('be.visible');
  // Verify the counter on the checkouts nav link
  cy.get('[data-testid="checkout-counter"]')
    .should('be.visible')
    .and('have.text', '1');
});

it('Verify returning items from checkouts page - @T73acc852', () => {
  cy.login('administrator');
  // Checkout option exists
  cy.visit(`/checkouts`);
  // find the row for this media object
  cy.get('[data-testid="checkout-row"]')
    .contains('[data-testid="checkout-media-title"]', media_object_title)
    .should('be.visible')
    .closest('[data-testid="checkout-row"]')
    .as('row');

  // verify Return exists in that row, then click it
  cy.get('@row')
    .find('[data-testid="checkout-return"]')
    .should('be.visible')
    .click();
  // Verify that the item is no longer in the checkouts list
  cy.get('[data-testid="checkouts-table"]').within(() => {
    cy.contains(
      '[data-testid="checkout-media-title"]',
      media_object_title
    ).should('not.exist');
  });

  // Verify the counter on the checkouts nav link is updated
  cy.get('[data-testid="checkout-counter"]')
    .should('be.visible')
    .and('have.text', '0');

  cy.visit('/media_objects/' + media_object_id);
  // verify the borrow gate text is shown
  cy.get('.checkout .centered.video')
    .should('be.visible')
    .within(() => {
      cy.contains('p', 'Borrow this item to access media resources.').should(
        'be.visible'
      );

      // verify the borrow button
      cy.get('input[type="submit"][value="Borrow for 14 days"]').should(
        'be.visible'
      );
    });
});

it('Verify changing the default lending period for a CDL collection - apply to all existing items - @T33474bca', () => {
  cy.login('administrator');
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="add-lending-period-days"]').clear().type('3');
  cy.on('window:confirm', () => true);
  cy.get('[data-testid="lending-period-apply-to-all"]').click();
  cy.get('[data-testid="add-lending-period-days"]').should('have.value', '3');
  //verify that the lending period for the existing item is updated to 3 days
  cy.visit('/media_objects/' + media_object_id);
  cy.get('input[type="submit"][value="Borrow for 3 days"]')
    .should('be.visible')
    .and('have.value', 'Borrow for 3 days');
  cy.get('[data-testid="media-object-edit-btn"]').click();
  //Verify in access control tab lending period is updated to 3 days
  cy.get('[data-testid="media-object-lending-period-days"]').should(
    'have.value',
    '3'
  );
});

it('Verify Turning CDL off for a collection- @Tf26d8884', () => {
  cy.login('administrator');
  // Checkout option exists
  cy.get('a[href="/checkouts"]').should('exist').and('be.visible');
  // Navigate to collection page and turn CDL off
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="cdl-enable-checkbox"]').click({ force: true });
  cy.get('[data-testid="cdl-save-setting"]').click();
  cy.visit('/media_objects/' + media_object_id);
  //Click on borrow button and verify the media player is shown
  cy.get('input[type="submit"][value="Borrow for 14 days"]').click();
  cy.get('button[title="Play Video"]')
    .should('be.visible')
    .and('contain', 'Play Video');
  cy.contains('Details').should('be.visible');
  cy.contains('Sections').should('be.visible');
  cy.get('[data-testid="media-object-return-now-btn"]').should('be.visible');
});

it('Verify that the checkouts page displays the list of borrowed items - @T33474bca', () => {
  cy.login('administrator');
  cy.visit(`/checkouts`);
  // Click on display returned items checkbox
  cy.get('[data-testid="inactive-checkouts-toggle"]').click();
  //search for the returned item
  cy.get('input[type="search"][aria-controls="checkouts-table"]')
    .clear()
    .type(media_object_title);
  // Verify that the returned item is displayed
  cy.get('[data-testid="checkout-row"]')
    .contains('[data-testid="checkout-media-title"]', media_object_title)
    .should('be.visible')
    .closest('[data-testid="checkout-row"]');
});
