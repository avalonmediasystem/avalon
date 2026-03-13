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

// Run CDL-off test only when CDL_ENABLED is explicitly false in the env config.
// Run all other CDL tests only when CDL is enabled (the default).
const itIfCDLEnabled = Cypress.env('CDL_ENABLED') !== false ? it : it.skip;
const itIfCDLDisabled = Cypress.env('CDL_ENABLED') === false ? it : it.skip;

context('Selected Items', () => {
  var unit_title = `Automation unit title ${
    Math.floor(Math.random() * 10000) + 1
  }`;

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
        "Cannot read properties of undefined (reading 'success')",
      ) ||
      err.message.includes(
        "Cannot read properties of undefined (reading 'times')",
      )
    ) {
      return false;
    }
  });

  // Create unit, collection and media object before all tests
  before(() => {
    if (Cypress.env('CDL_ENABLED') === false) return;
    cy.login('administrator');
    unitPage.createUnit({ title: unit_title });
    navigateToManageContent();

    // Create collection linked to the unit created above
    collectionPage.createCollection(
      { title: collection_title, unitName: unit_title },
      { setPublicAccess: false },
    );

    // Navigate to the collection and create a media object
    collectionPage.navigateToCollection(collection_title);

    collectionPage
      .createItem(media_object_title, 'test_sample.mp4')
      .then((id) => {
        media_object_id = id;
        // Publish the item so it is accessible for CDL tests
        cy.get('[data-testid="media-object-publish-btn"]')
          .contains('Publish')
          .click();
        cy.get('[data-testid="alert"]').contains(
          'Media object successfully published.',
        );
      });
  });

  // Clean up after all tests - ITEM FIRST, THEN COLLECTION, THEN UNIT
  after(() => {
    if (Cypress.env('CDL_ENABLED') === false) return;
    cy.login('administrator');
    if (media_object_id) {
      collectionPage.deleteItemById(media_object_id);
    }
    collectionPage.deleteCollectionByName(collection_title);
    UnitPage.deleteUnitByName(unit_title);
  });

  itIfCDLDisabled(
    'Verify that the checkouts menu option does not display if CDL is not enabled for Avalon - @Tf7bf6b9a',
    () => {
      cy.login('administrator');
      //cy.get('[data-testid="checkout-counter"]').should('have.text', '0');
      unitPage.createUnit({ title: unit_title });
      navigateToManageContent();
      // Create collection linked to the unit created above
      collectionPage.createCollection(
        { title: collection_title, unitName: unit_title },
        { setPublicAccess: false },
      );
      collectionPage.navigateToCollection(collection_title);
      cy.get('[data-testid="collection-enable-cdl-card"]').should('not.exist');
      cy.get('[data-testid="collection-item-lending-period-card"]').should(
        'not.exist',
      );
      collectionPage.deleteCollectionByName(collection_title);
      UnitPage.deleteUnitByName(unit_title);
    },
  );

  itIfCDLEnabled('Verify CDL is enabled - @T3c2f5e2e', () => {
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

  itIfCDLEnabled(
    'Enable CDL for a collection and borrow an item - @T3c2f5e2e @T17a682cb @T729f3ed0',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      // Checkout option exists
      cy.get('a[href="/checkouts"]').should('exist').and('be.visible');
      // Navigate to collection page and enable CDL
      collectionPage.navigateToCollection(collection_title);
      cy.get('[data-testid="cdl-enable-checkbox"]').click({ force: true });
      cy.get('[data-testid="cdl-save-setting"]').click();
      cy.visit('/media_objects/' + media_object_id);
      // Capture the counter value before borrowing
      cy.get('[data-testid="checkout-counter"]')
        .invoke('text')
        .then((countBefore) => {
          const before = parseInt(countBefore, 10);
          // verify the borrow gate is shown
          cy.get('.checkout .centered.video')
            .should('be.visible')
            .within(() => {
              cy.contains(
                'p',
                'Borrow this item to access media resources.',
              ).should('be.visible');
              // verify the borrow button (lending period is dynamic so use partial match)
              cy.contains('input[type="submit"]', 'Borrow for').should(
                'be.visible',
              );
            });
          // Click on borrow button and verify the media player is shown
          cy.contains('input[type="submit"]', 'Borrow for').click();
          cy.get('[data-testid="media-player"]').should('be.visible');
          cy.contains('Details').should('be.visible');
          cy.get('[data-testid="media-object-return-now-btn"]').should(
            'be.visible',
          );
          // Verify the counter increased by 1
          cy.get('[data-testid="checkout-counter"]')
            .should('be.visible')
            .invoke('text')
            .then((countAfter) => {
              expect(parseInt(countAfter, 10)).to.eq(before + 1);
            });
        });
    },
  );

  itIfCDLEnabled(
    'Verify returning items from checkouts page - @T73acc852',
    () => {
      cy.login('administrator');
      cy.visit(`/checkouts`);
      // Capture the counter value before returning
      cy.get('[data-testid="checkout-counter"]')
        .invoke('text')
        .then((countBefore) => {
          const before = parseInt(countBefore, 10);
          // Find the row with the media object title
          cy.get('[data-testid="checkouts-table-body"]')
            .contains('a', media_object_title)
            .should('be.visible')
            .closest('tr')
            .as('row');

          // Verify "Return" button exists and click it
          cy.get('@row')
            .find('a[href*="/return"]')
            .should('be.visible')
            .click();

          // Verify the item is no longer listed in the table
          cy.get('[data-testid="checkouts-table-body"]').should(
            'not.contain',
            media_object_title,
          );

          // Navigate to the media object page to confirm the checkout was returned
          cy.visit('/media_objects/' + media_object_id);
          cy.get('.checkout .centered.video')
            .should('be.visible')
            .within(() => {
              cy.contains(
                'p',
                'Borrow this item to access media resources.',
              ).should('be.visible');
              cy.contains('input[type="submit"]', 'Borrow for').should(
                'be.visible',
              );
            });
          // verify decreased by 1
          cy.get('[data-testid="checkout-counter"]')
            .should('be.visible')
            .invoke('text')
            .then((countAfter) => {
              expect(parseInt(countAfter, 10)).to.eq(before - 1);
            });
        });
    },
  );

  itIfCDLEnabled(
    'Verify changing the default lending period for a CDL collection - apply to all existing items - @T8a59578a',
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.get('[data-testid="add-lending-period-days"]').clear().type('3');
      cy.on('window:confirm', () => true);
      cy.get('[data-testid="lending-period-apply-to-all"]').click();
      cy.get('[data-testid="add-lending-period-days"]').should(
        'have.value',
        '3',
      );
      // Verify that the lending period for the existing item is updated to 3 days
      cy.visit('/media_objects/' + media_object_id);
      cy.contains('input[type="submit"]', 'Borrow for 3 days')
        .should('be.visible')
        .and('have.value', 'Borrow for 3 days');
      // Verify in access-control edit step that lending period is updated to 3 days
      cy.visit(
        '/media_objects/' + media_object_id + '/edit?step=access-control',
      );
      cy.get('[data-testid="media-object-lending-period-days"]').should(
        'have.value',
        '3',
      );
    },
  );

  itIfCDLEnabled('Verify Turning CDL off for a collection - @Tf26d8884', () => {
    cy.login('administrator');
    // Checkout option exists
    cy.get('a[href="/checkouts"]').should('exist').and('be.visible');
    // Navigate to collection page and disable CDL
    collectionPage.navigateToCollection(collection_title);
    cy.get('[data-testid="cdl-enable-checkbox"]').click({ force: true });
    cy.get('[data-testid="cdl-save-setting"]').click();
    cy.visit('/media_objects/' + media_object_id);
    // With CDL disabled, the borrow gate should not appear
    cy.get('.checkout').should('not.exist');
    // Media player is directly accessible without borrowing
    cy.get('[data-testid="media-player"]').should('be.visible');
    cy.contains('Details').should('be.visible');
  });

  itIfCDLEnabled(
    'Verify that the checkouts page displays the list of borrowed items - @T33474bca',
    () => {
      cy.login('administrator');
      cy.visit(`/checkouts`);
      // Click on display returned items checkbox
      cy.get('[data-testid="bookmark-display-returned-items-chkbox"]')
        .should('exist')
        .click();
      // Search for the returned item using the table's search field
      cy.get('[data-testid="checkouts-table-search-field"]')
        .clear()
        .type(media_object_title);
      // Verify that the returned item is displayed
      cy.get('[data-testid="checkouts-table-body"]')
        .contains('a', media_object_title)
        .should('be.visible')
        .closest('tr')
        .as('row');
    },
  );
});
