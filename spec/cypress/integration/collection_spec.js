import HomePage from '../pageObjects/homePage.js';
import CollectionPage from '../pageObjects/collectionPage';
import ItemPage from '../pageObjects/itemPage.js';
import { getFixturePath } from '../support/utils';
import UnitPage from '../pageObjects/unitPage.js';

import {
  navigateToManageContent,
  selectCollectionUnit,
  performSearch,
} from '../support/navigation.js';

const collectionPage = new CollectionPage();
const homePage = new HomePage();
const itemPage = new ItemPage();
const unitPage = UnitPage;
context('Collections Test', () => {
  var unit_title = `Automation unit title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  //Admin created collection
  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;

  //Collection name created by manager
  const collectionNameManager = `Automation collection title - manager${
    Math.floor(Math.random() * 10000) + 1
  }`;
  let createdItemIds = [];

  var item_title; //This is an item under collection created by admin
  var item_id;
  var item_title_discovery; // This is an item created to test out
  var item_id_discovery;

  Cypress.on('uncaught:exception', (err, runnable) => {
    // Prevents Cypress from failing the test due to uncaught exceptions in the application code  - TypeError: Cannot read properties of undefined (reading 'scrollDown')
    if (
      err.message.includes(
        "Cannot read properties of undefined (reading 'success')",
      )
    ) {
      return false;
    }
  });

  before(() => {
    // creating unit for collection
    cy.login('administrator');
    unitPage.createUnit({ title: unit_title });
  });

  // Cleanup after all tests
  after(() => {
    cy.login('administrator');

    // Delete item first
    createdItemIds.forEach((id) => {
      collectionPage.deleteItemById(id);
    });

    // Delete manager collection
    collectionPage.deleteCollectionByName(collectionNameManager);

    // Delete main collection
    collectionPage.deleteCollectionByName(collection_title);

    // Delete unit
    UnitPage.deleteUnitByName(unit_title);
  });

  it(
    'Verify whether an admin user is able to create a collection - @T553cda51 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      navigateToManageContent();
      collectionPage.createCollection({
        title: collection_title,
        unitName: unit_title,
      });
    },
  );

  it('Verify that the regular users and public do not have access to manage content - @T6a305228', () => {
    //Logging in as user and verifying user does not have access to manage
    cy.login('user');
    cy.visit('/');
    cy.contains('Manage').should('not.exist');
    homePage.logout();
    // Verifying public does not have access to manage
    cy.visit('/');
    cy.contains('Manage').should('not.exist');
  });

  it(
    'Verify whether a user who is an admin or manager can assign other users as managers to the collection- @T3c428871 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      collectionPage.addManager(Cypress.env('USERS_UNITMANAGER_USERNAME')); //manager@example.com added
      collectionPage.addManager(Cypress.env('USERS_MANAGER_USERNAME')); //add unitmanager@example.com for the next test case because it does not let you remove the manager even if there is inherited managerf from unit.
      //verifying the manager has access to the collection
      cy.login('manager');
      navigateToManageContent();
      cy.contains(collection_title).should('exist');
    },
  );

  it('Verify removing users from assigned staff roles for the collection - @T04aa5c88', () => {
    var managerUsername = Cypress.env('USERS_MANAGER_USERNAME');
    var adminUsername = Cypress.env('USERS_ADMINISTRATOR_USERNAME');
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    cy.intercept('POST', '/admin/collections/*').as('updateCollectionManager');

    // Verifying collection manager exists
    cy.get("[data-testid='collection-access-label-manager']")
      .should('exist')
      .find('label')
      .filter((_, el) => el.textContent.trim() === managerUsername)
      .should('have.length', 1)
      .should('be.visible');

    // Removing manager access for the collection
    cy.get('[data-testid="collection-access-label-manager"]')
      .find('label')
      .filter((_, el) => el.textContent.trim() === managerUsername)
      .parents('tr')
      .find('[data-testid="collection-access-remove-manager"]')
      .click();

    cy.wait('@updateCollectionManager').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include(
        '/admin/collections/',
      );
    });
    //Verifying manager is removed
    cy.get("[data-testid='collection-access-label-manager']")
      .find('label')
      .filter((_, el) => el.textContent.trim() === managerUsername)
      .should('have.length', 0);

    cy.login('manager');
    navigateToManageContent();

    //adding the manager back again for rest of the test cases
    cy.contains(collection_title).should('not.exist');
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    collectionPage.addManager(Cypress.env('USERS_MANAGER_USERNAME'));
  });

  it('Verify that only the admins and managers can create a collection - @T680b0e35', () => {
    let collectionurl;
    // Manager can create collection
    cy.login('manager');
    navigateToManageContent();

    collectionPage.createCollection({
      title: collectionNameManager,
      contactEmail: 'manager@example.com',
      unitName: unit_title,
    });
    cy.url().then((url) => {
      collectionurl = url;
    });
    homePage.logout();

    //User cannot access the collection
    cy.login('user');
    cy.visit('/');
    cy.contains('Manage').should('not.exist');
    homePage.logout();

    //administrator adds user as depositor
    cy.login('administrator');
    navigateToManageContent();
    collectionPage.navigateToCollection(collectionNameManager);
    cy.intercept('POST', '/admin/collections/*').as('updateCollectionManager');
    cy.get('[data-testid="add_depositor-user-input"]')
      .type(Cypress.env('USERS_USER_USERNAME'))
      .should('have.value', Cypress.env('USERS_USER_USERNAME'));
    cy.get('[data-testid="add_depositor-popup"]')
      .contains(Cypress.env('USERS_USER_USERNAME'))
      .click();
    cy.get("[data-testid='submit-add-depositor']").click();
    cy.wait('@updateCollectionManager')
      .its('response.statusCode')
      .should('eq', 302);
    homePage.logout();

    //user can now access the collection
    cy.login('user');
    cy.visit('/');
    cy.contains('Manage').should('exist').click();
    cy.then(() => {
      cy.visit(collectionurl);
    });
  });

  it('Verify editing item discovery - Checking the Hide this item from search results for new items in the collection - @T7108664f @T126023f1', () => {
    // Variables for new created item
    var item_title_hidden = `Automation Item title ${
      Math.floor(Math.random() * 100000) + 1
    }`;
    var item_id_hidden;

    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    item_title_discovery = `Automation Item title ${
      Math.floor(Math.random() * 100000) + 1
    }`;
    // Creating an item as an existing item so we can check the precondition
    collectionPage
      .createItem(item_title_discovery, 'test_sample.mp4')
      .then((id) => {
        item_id_discovery = id;
        createdItemIds.push(id);
        cy.intercept('POST', '**/update_status?status=publish').as(
          'publishmedia',
        );
        cy.get('[data-testid="media-object-publish-btn"]')
          .contains('Publish')
          .click();
        cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
        cy.get('[data-testid="alert"]').contains(
          'Media object successfully published.',
        );
        cy.wait(5000);
        cy.get('[data-testid="media-object-unpublish-btn"]').contains(
          'Unpublish',
        );

        cy.visit('/media_objects/' + item_id_discovery);
      });
    cy.waitForVideoReady();
    //setting it to be available to general public
    cy.get('[data-testid="media-object-edit-btn"]').click();
    cy.get('[data-testid="media-object-general-public"]')
      .check()
      .should('be.checked');
    cy.get('[data-testid="media-object-continue-btn"]').click();

    // Login as normal user and verify if the user can search the item
    cy.visit('/users/sign_out');
    cy.login('user');
    homePage.getBrowseNavButton();
    performSearch(item_title_discovery);

    cy.get('[data-testid="browse-results-list"]').within(() => {
      cy.contains(
        '[data-testid^="browse-document-title-"]',
        item_title_discovery,
      ).should('exist');
    });

    // Checking the "Hide this item from search result"
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    // Make sure the checkbox exists and is visible
    cy.get('[data-testid="collection-hide-checkbox"]')
      .should('exist')
      .should('be.visible');

    // Check the checkbox
    cy.get('[data-testid="collection-hide-checkbox"]')
      .check()
      .should('be.checked');

    // Verify the label text wraps the checkbox correctly
    cy.get('[data-testid="collection-hide-checkbox"]')
      .parent('label')
      .should('contain.text', 'Hide this item from search results');

    //Click on save setting button
    cy.get('[data-testid="collection-item-discovery"]')
      .find('[data-testid="collection-save-setting-btn"]')
      .contains('Save Setting')
      .click();

    // Checking for an exitsing item
    //admin
    performSearch(item_title_discovery);

    cy.get('[data-testid="browse-results-list"]').within(() => {
      cy.contains(
        '[data-testid^="browse-document-title-"]',
        item_title_discovery,
      ).should('exist');
    });

    //user
    cy.login('user');
    homePage.getBrowseNavButton();
    performSearch(item_title_discovery);

    cy.get('[data-testid="browse-results-list"]').within(() => {
      cy.contains(
        '[data-testid^="browse-document-title-"]',
        item_title_discovery,
      ).should('exist');
    });
    // Creating a new item
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    // Creating a new item - search on this should be hiddem
    collectionPage
      .createItem(item_title_hidden, 'test_sample.mp4')
      .then((id) => {
        item_id_hidden = id;
        createdItemIds.push(id);
        cy.intercept('POST', '**/update_status?status=publish').as(
          'publishmedia',
        );
        cy.get('[data-testid="media-object-publish-btn"]')
          .contains('Publish')
          .click();
        cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
        cy.get('[data-testid="alert"]').contains(
          'Media object successfully published.',
        );
        cy.wait(5000);
        cy.get('[data-testid="media-object-unpublish-btn"]').contains(
          'Unpublish',
        );

        cy.visit('/media_objects/' + item_id_hidden);
      });

    //setting it to be available to general public
    cy.get('[data-testid="media-object-edit-btn"]').click();
    cy.get('[data-testid="media-object-general-public"]')
      .check()
      .should('be.checked');
    cy.get('[data-testid="media-object-continue-btn"]').click();

    // Checking for new item - normal user
    cy.login('user');
    homePage.getBrowseNavButton();
    performSearch(item_title_hidden);

    cy.get('body').then(($body) => {
      if ($body.find('[data-testid="browse-results-list"]').length > 0) {
        // If the container exists, check that the title is not found within it
        cy.get('[data-testid="browse-results-list"]').within(() => {
          cy.contains(item_title_hidden).should('not.exist');
        });
      } else {
        cy.log(
          'No items visible in browse results — skipping title assertion.',
        );
      }
    });
  });

  it('Verify editing item discovery - Checking the Hide this item from search results for existing items in the collection - @T234440d9', () => {
    // Variables for new created item
    var item_title_hidden = `Automation Item title ${
      Math.floor(Math.random() * 100000) + 1
    }`;
    var item_id_hidden;
    // Login as admin and verify the user can search the existing item
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    homePage.getBrowseNavButton();
    performSearch(item_title_discovery);

    cy.get('[data-testid="browse-results-list"]').within(() => {
      cy.contains(
        '[data-testid^="browse-document-title-"]',
        item_title_discovery,
      ).should('exist');
    });

    // Login as normal user and verify the user can search the existing item
    cy.visit('/users/sign_out');
    cy.login('user');
    homePage.getBrowseNavButton();
    performSearch(item_title_discovery);

    cy.get('[data-testid="browse-results-list"]').within(() => {
      cy.contains(
        '[data-testid^="browse-document-title-"]',
        item_title_discovery,
      ).should('exist');
    });

    // Checking the "Hide this item from search result" and applying to all existing items

    // Verify the checkbox is checked from previous test case
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    cy.get('[data-testid="collection-hide-checkbox"]').should('be.checked');

    // Click on save setting button
    cy.get('[data-testid="collection-item-discovery"]')
      .find('[data-testid="collection-apply-to-all-btn"]')
      .contains('Apply to All Existing Items')
      .click();

    // Checking for an exitsing item
    //admin
    cy.login('administrator');
    homePage.getBrowseNavButton();
    performSearch(item_title_discovery);

    cy.get('[data-testid="browse-results-list"]').within(() => {
      cy.contains(
        '[data-testid^="browse-document-title-"]',
        item_title_discovery,
      ).should('exist');
    });

    //user
    cy.login('user');
    homePage.getBrowseNavButton();
    performSearch(item_title_discovery);
    cy.get('body').then(($body) => {
      if ($body.find('[data-testid="browse-results-list"]').length > 0) {
        // If the container exists, check that the title is not found within it
        cy.get('[data-testid="browse-results-list"]').within(() => {
          cy.contains(item_title_discovery).should('not.exist');
        });
      } else {
        cy.log(
          'No items visible in browse results — skipping title assertion.',
        );
      }
    });
    // Creating a new item
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    // Creating a new item - search on this should be hiddem
    collectionPage
      .createItem(item_title_hidden, 'test_sample.mp4')
      .then((id) => {
        item_id_hidden = id;
        createdItemIds.push(id);
        cy.intercept('POST', '**/update_status?status=publish').as(
          'publishmedia',
        );
        cy.get('[data-testid="media-object-publish-btn"]')
          .contains('Publish')
          .click();
        cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
        cy.get('[data-testid="alert"]').contains(
          'Media object successfully published.',
        );
        cy.wait(5000);
        cy.get('[data-testid="media-object-unpublish-btn"]').contains(
          'Unpublish',
        );

        cy.visit('/media_objects/' + item_id_hidden);
      });

    //setting it to be available to general public
    cy.get('[data-testid="media-object-edit-btn"]').click();
    cy.get('[data-testid="media-object-general-public"]')
      .check()
      .should('be.checked');
    cy.get('[data-testid="media-object-continue-btn"]').click();

    // Checking for new item - normal user
    cy.login('user');
    homePage.getBrowseNavButton();
    performSearch(item_title_hidden);

    cy.get('body').then(($body) => {
      if ($body.find('[data-testid="browse-results-list"]').length > 0) {
        // If the container exists, check that the title is not found within it
        cy.get('[data-testid="browse-results-list"]').within(() => {
          cy.contains(item_title_discovery).should('not.exist');
        });
      } else {
        cy.log(
          'No items visible in browse results — skipping title assertion.',
        );
      }
    });
  });

  it(
    'Verify adding Avalon user in assign special access for a user - @T553cda51 @T2a81c8fd',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      //pre condition - setting the collection item access to be collection staff only so that we can verify the special access functionality
      cy.get("[data-testid='collection-item-access']").within(() => {
        cy.contains('label', 'Collection staff only')
          .find("[data-testid='collection-checkbox-collection-staff']")
          .click()
          .should('be.checked');
        cy.get("[data-testid='collection-apply-to-existing-btn']").click();
      });

      cy.intercept('POST', '/admin/collections/*').as('updateSpecialAccess');

      // Add user to special access
      cy.get('[data-testid="add_user-user-input"]')
        .type(Cypress.env('USERS_USER_USERNAME'))
        .should('have.value', Cypress.env('USERS_USER_USERNAME'));
      cy.get('[data-testid="add_user-popup"]')
        .contains(Cypress.env('USERS_USER_USERNAME'))
        .click();
      cy.get('[data-testid="submit-add-user"]').click();

      cy.wait('@updateSpecialAccess')
        .its('response.statusCode')
        .should('eq', 302);

      // Verify user appears in the special access list
      cy.get('[data-testid="collection-access-label-user"]')
        .should('exist')
        .contains('label', Cypress.env('USERS_USER_USERNAME'))
        .should('be.visible');

      // Create a new item after special access is configured and track its ID
      collectionPage.navigateToCollection(collection_title);
      const specialAccessItemTitle = `Automation Special Access Item ${Math.floor(Math.random() * 10000) + 1}`;
      collectionPage
        .createItem(specialAccessItemTitle, 'test_sample.mp4')
        .then((newItemId) => {
          createdItemIds.push(newItemId);

          // Publish the newly created item
          cy.intercept('POST', '**/update_status?status=publish').as(
            'publishmedia',
          );
          cy.get('[data-testid="media-object-publish-btn"]')
            .contains('Publish')
            .click();
          cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
          cy.get('[data-testid="media-object-unpublish-btn"]')
            .contains('Unpublish')
            .should('be.visible');

          // Verify user can access all items including newly created one
          cy.login('user');
          cy.wrap(createdItemIds).each((itemId) => {
            cy.log(`Verifying special access for item: ${itemId}`);
            cy.intercept('GET', '/media_objects/*').as('getmediaobject');
            cy.visit('/media_objects/' + itemId);
            cy.wait('@getmediaobject').then((interception) => {
              expect(interception.response.statusCode).to.eq(200);
            });
          });
        });
    },
  );

  it('Verify removing a user/group/ip address assigned for special access in the collection - @T6b4b1eab', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);

    cy.intercept('POST', '/admin/collections/*').as('updateSpecialAccess');

    // Verify user is currently in the special access list
    cy.get('[data-testid="collection-access-label-user"]')
      .should('exist')
      .contains('label', Cypress.env('USERS_USER_USERNAME'))
      .should('be.visible');

    // Remove user from special access
    cy.get('[data-testid="collection-access-remove-user"]').click();

    cy.wait('@updateSpecialAccess')
      .its('response.statusCode')
      .should('eq', 302);

    // Verify existing items are no longer accessible to user after removal
    cy.login('user');
    cy.wrap(createdItemIds).each((itemId) => {
      cy.log(`Verifying removed special access for item: ${itemId}`);
      cy.intercept('GET', '/media_objects/*').as('getmediaobjectExisting');
      cy.visit('/media_objects/' + itemId, { failOnStatusCode: false });
      cy.wait('@getmediaobjectExisting')
        .its('response.statusCode')
        .should('eq', 401);
    });
  });

  it(
    "Verify whether the user is able to search for Collections-'@Tf7cefb09 ",
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.get('a[href="/collections"]')
        .contains(/Collections$/)
        .should('be.visible')
        .click();
      cy.get("[data-testid='collection-search-collection-input']")
        .type(collection_title)
        .should('have.value', collection_title);
      cy.get("[data-testid='collection-card-body']").contains(
        'a',
        collection_title,
      );
    },
  );

  it(
    'Setting default access control for new item - Verify changing item access - Collection staff only  - @T9978b4f7 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.intercept('POST', '/admin/collections/*').as('updateAccessControl');
      cy.get("[data-testid='collection-item-access']").within(() => {
        cy.contains('label', 'Collection staff only')
          .find("[data-testid='collection-checkbox-collection-staff']")
          .click()
          .should('be.checked');
        cy.get("[data-testid='collection-save-setting-btn']").click();
      });
      cy.wait('@updateAccessControl')
        .its('response.statusCode')
        .should('eq', 302);
      cy.contains('label', 'Collection staff only')
        .find("[data-testid='collection-checkbox-collection-staff']")
        .should('be.checked');

      // Create a new item to verify it inherits collection staff only access
      var item_title_staff_only = `Automation Item title ${
        Math.floor(Math.random() * 100000) + 1
      }`;
      collectionPage
        .createItem(item_title_staff_only, 'test_sample.mp4')
        .then((id) => {
          createdItemIds.push(id);
          cy.intercept('POST', '**/update_status?status=publish').as(
            'publishmedia',
          );
          cy.get('[data-testid="media-object-publish-btn"]')
            .contains('Publish')
            .click();
          cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
          cy.get('[data-testid="alert"]').contains(
            'Media object successfully published.',
          );
          cy.wait(5000);
          cy.get('[data-testid="media-object-unpublish-btn"]').contains(
            'Unpublish',
          );
          // Verify the new item is only accessible to collection staff
          itemPage.verifyCollecttionStaffAccess(id);
        });
    },
  );

  it(
    'Apply to all existing items - Verify changing item access - Collection staff only - @Tdcf756bd',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.intercept('POST', '/admin/collections/*').as('updateAccessControl');
      cy.get("[data-testid='collection-item-access']").within(() => {
        cy.contains('label', 'Collection staff only')
          .find("[data-testid='collection-checkbox-collection-staff']")
          .click()
          .should('be.checked');
        cy.get("[data-testid='collection-apply-to-existing-btn']").click();
      });
      cy.wait('@updateAccessControl')
        .its('response.statusCode')
        .should('eq', 302);
      cy.contains('label', 'Collection staff only')
        .find("[data-testid='collection-checkbox-collection-staff']")
        .should('be.checked');
      cy.wrap(createdItemIds).each((itemId) => {
        itemPage.verifyCollecttionStaffAccess(itemId);
      });
    },
  );

  it('Setting default access control for new item - Verify changing item access - Logged in users only', () => {
    var item_title_logged_in = `Automation Item title ${
      Math.floor(Math.random() * 100000) + 1
    }`;
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    cy.intercept('POST', '/admin/collections/*').as('updateAccessControl');
    cy.get("[data-testid='collection-item-access']").within(() => {
      cy.contains('label', 'Logged in users only')
        .find("[data-testid='collection-checkbox-logged-in-user']")
        .click()
        .should('be.checked');
      cy.get("[data-testid='collection-save-setting-btn']").click();
    });
    cy.wait('@updateAccessControl')
      .its('response.statusCode')
      .should('eq', 302);
    cy.contains('label', 'Logged in users only')
      .find("[data-testid='collection-checkbox-logged-in-user']")
      .should('be.checked');

    // Create a new item to verify it inherits logged in users only access
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    collectionPage
      .createItem(item_title_logged_in, 'test_sample.mp4')
      .then((id) => {
        createdItemIds.push(id);
        cy.intercept('POST', '**/update_status?status=publish').as(
          'publishmedia',
        );
        cy.get('[data-testid="media-object-publish-btn"]')
          .contains('Publish')
          .click();
        cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
        cy.get('[data-testid="alert"]').contains(
          'Media object successfully published.',
        );
        cy.wait(5000);
        cy.get('[data-testid="media-object-unpublish-btn"]').contains(
          'Unpublish',
        );
        cy.visit('/media_objects/' + id);
        // Verify the new item is accessible to logged in users but not public
        itemPage.verifyLoggedInUserAccess(id);
      });
  });

  it('Apply to all existing items - Verify changing item access - Logged in users only', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    cy.intercept('POST', '/admin/collections/*').as('updateAccessControl');
    cy.get("[data-testid='collection-item-access']").within(() => {
      cy.contains('label', 'Logged in users only')
        .find("[data-testid='collection-checkbox-logged-in-user']")
        .click()
        .should('be.checked');
      cy.get("[data-testid='collection-apply-to-existing-btn']").click();
    });
    cy.wait('@updateAccessControl').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include(
        '/admin/collections/',
      );
    });
    cy.contains('label', 'Logged in users only')
      .find("[data-testid='collection-checkbox-logged-in-user']")
      .should('be.checked');

    // Verify all existing items are accessible to logged in users but not public
    cy.wrap(createdItemIds).each((itemId) => {
      itemPage.verifyLoggedInUserAccess(itemId);
    });
  });

  it('Setting default access control for new item - Verify changing item access - Available to the general public - @Tcc0080ba', () => {
    var item_title_general_public = `Automation Item title ${
      Math.floor(Math.random() * 100000) + 1
    }`;
    var item_id_general_public;
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    //set the access to avaialble to general public
    collectionPage.setPublicAccess();
    //create an item
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    // Creating a new item - search on this should be hiddem
    collectionPage
      .createItem(item_title_general_public, 'test_sample.mp4')
      .then((id) => {
        item_id_general_public = id;
        createdItemIds.push(id);
        cy.intercept('POST', '**/update_status?status=publish').as(
          'publishmedia',
        );
        cy.get('[data-testid="media-object-publish-btn"]')
          .contains('Publish')
          .click();
        cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
        cy.get('[data-testid="alert"]').contains(
          'Media object successfully published.',
        );
        cy.wait(5000);
        cy.get('[data-testid="media-object-unpublish-btn"]').contains(
          'Unpublish',
        );

        cy.visit('/media_objects/' + item_id_general_public);
        //check with normal user if they can access
        itemPage.verifyGeneralPublicAccess(item_id_general_public);
      });
  });

  it('Apply to all existing items - Verify changing item access - Available to the general public - @T906c672e', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    //set the access to avaialble to general public
    cy.intercept('POST', '/admin/collections/*').as('updateAccessControl');
    cy.get("[data-testid='collection-item-access']").within(() => {
      cy.contains('label', 'Available to the general public')
        .find("[data-testid='collection-checkbox-general-public']")
        .click()
        .should('be.checked');
      cy.get("[data-testid='collection-apply-to-existing-btn']").click();
    });

    cy.wait('@updateAccessControl').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include(
        '/admin/collections/',
      );
    });

    cy.contains('label', 'Available to the general public')
      .find("[data-testid='collection-checkbox-general-public']")
      .should('be.checked');

    //check if all the existing items in that collection can be accessed by all the users and also without logging in
    cy.wrap(createdItemIds).each((itemId) => {
      cy.log(`Verifying public access for item: ${itemId}`);
      itemPage.verifyGeneralPublicAccess(itemId);
    });
  });

  it(
    'Verify whether a user is able to update Collection information - @Ta1b2fef8 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.get("[data-testid='collection-edit-collection-info']")
        .should('exist')
        .and('contain.text', 'Edit Collection Info')
        .click();
      cy.wait(5000);
      cy.location('pathname').then((path) => {
        const collectionId = path.split('/').pop();
        cy.intercept('POST', `/admin/collections/${collectionId}.json`).as(
          'updateCollectionInfo',
        );
      });

      cy.get("[data-testid='collection-update-contact-email']")
        .clear()
        .type('test1@mail.com');
      var new_title = `Updated automation title ${
        Math.floor(Math.random() * 10000) + 1
      }`;
      cy.get("[data-testid='collection-update-name']input")
        .clear()
        .type(new_title);
      var updatedDescription = ' Adding more details to collection description';
      cy.get("[data-testid='collection-update-description']")
        .invoke('val')
        .then((existingText) => {
          updatedDescription = existingText + updatedDescription;
          cy.get("[data-testid='collection-update-description']").type(
            updatedDescription,
          );
        });
      cy.get("[data-testid='collection-update-collection-btn']").click();
      cy.wait('@updateCollectionInfo')
        .its('response.statusCode')
        .should('eq', 200);
      cy.get("[data-testid='collection-collection-details']")
        .should('contain.text', new_title)
        .then(() => {
          collection_title = new_title;
        });
      cy.get("[data-testid='collection-collection-details']").within(() => {
        cy.get("[data-testid='collection-contact-email']").should(
          'have.text',
          'test1@mail.com',
        );
        cy.get("[data-testid='collection-description']").should(
          'contain.text',
          updatedDescription,
        );
      });
    },
  );

  it('Verify whether a user is able to update poster image -  @T26526b2e ', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    cy.intercept('POST', '**/poster').as('updatePoster');
    cy.get("[data-testid='collection-poster-input']").selectFile(
      getFixturePath('image.png'),
      { force: true },
    );
    cy.wait(5000);
    cy.screenshot();
    cy.get("[data-testid='collection-upload-poster']").click();
    cy.wait('@updatePoster').its('response.statusCode').should('eq', 302);
    cy.get("[data-testid='alert']")
      .contains('Poster file successfully added.')
      .should('be.visible');
  });
  it('Verify limiting the items by Published status - @Tfd6bc70f', () => {
    cy.login('administrator');
    homePage.getBrowseNavButton().click();

    // Expand "Published" facet section
    cy.contains('button', 'Published').should('be.visible').click();

    // Get the count first
    cy.contains('li', 'Published')
      .should('be.visible')
      .find('span.facet-count')
      .invoke('text')
      .then((facetCount) => {
        const trimmedFacetCount = facetCount.trim();

        // Click the link to apply the filter
        cy.contains('li', 'Published').find('a.facet-select').click();

        // Wait for the page to update
        cy.url().should('include', '/catalog');
        cy.wait(1000); // Let the results load

        // Now get the total count from result page
        cy.get('span.page-entries')
          .find('strong')
          .last()
          .invoke('text')
          .then((resultCount) => {
            cy.log(
              `Facet: ${trimmedFacetCount} | Result: ${resultCount.trim()}`,
            );
            expect(trimmedFacetCount).to.eq(resultCount.trim());
          });

        //  Click on the first result
        cy.get('[data-testid^="browse-document-title-"]').first().click();

        // Validate you're on the detail page and see the Unpublish button
        cy.url().should('include', '/media_objects/');
        cy.waitForVideoReady();
        cy.get('[data-testid="media-object-unpublish-btn"]').should(
          'be.visible',
        );
      });
  });
  //delete a collection in after block - critical test case - @T959a56df and @T0e0a5611
});
