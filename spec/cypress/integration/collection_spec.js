import HomePage from '../pageObjects/homePage.js';
import CollectionPage from '../pageObjects/collectionPage';
import ItemPage from '../pageObjects/itemPage.js';
import { getFixturePath } from '../support/utils';

import {
  navigateToManageContent,
  selectCollectionUnit,
  performSearch,
} from '../support/navigation.js';

const collectionPage = new CollectionPage();
const homePage = new HomePage();
const itemPage = new ItemPage();
context('Collections Test', () => {
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
        "Cannot read properties of undefined (reading 'success')"
      )
    ) {
      return false;
    }
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
  });

  it(
    'Verify whether an admin user is able to create a collection - @T553cda51 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      navigateToManageContent();
      collectionPage.createCollection({ title: collection_title });
    }
  );

  it(
    'Verify that the regular users and public do not have access to manage content',
    { tags: '@high' },
    () => {
      //Logging in as user and verifying user does not have access to manage
      cy.login('user');
      cy.visit('/');
      cy.contains('Manage').should('not.exist');
      homePage.logout();
      // Verifying public does not have access to manage
      cy.visit('/');
      cy.contains('Manage').should('not.exist');
    }
  );

  it(
    'Verify whether an admin/manager is able assign other users as managers to the collection - @T3c428871 ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      collectionPage.addManager(Cypress.env('USERS_MANAGER_USERNAME'));
    }
  );

  it(
    'Verify removing users from assigned staff roles for the collection - @T04aa5c88',
    { tags: '@high' },
    () => {
      var managerUsername = Cypress.env('USERS_MANAGER_USERNAME');
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.intercept('POST', '/admin/collections/*').as(
        'updateCollectionManager'
      );

      // Verifying collection manager exists
      cy.get("[data-testid='collection-access-label-manager']")
        .should('exist')
        .contains('label', managerUsername)
        .should('be.visible');

      // Removing manager access for the collection
      cy.get('[data-testid="collection-access-label-manager"]')
        .contains('manager@example.com')
        .parents('tr')
        .find('[data-testid="collection-access-remove-manager"]')
        .click();

      cy.wait('@updateCollectionManager').then((interception) => {
        expect(interception.response.statusCode).to.eq(302);
        expect(interception.response.headers.location).to.include(
          '/admin/collections/'
        );
      });
      //Verifying manager is removed
      cy.get("[data-testid='collection-access-label-manager']")
        .contains('label', managerUsername)
        .should('not.exist');

      cy.login('manager');
      navigateToManageContent();

      //adding the manager back again for rest of the test cases
      cy.contains(collection_title).should('not.exist');
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      collectionPage.addManager(Cypress.env('USERS_MANAGER_USERNAME'));
    }
  );

  it(
    'Manager can create collection, normal user cannot, then depositor user cannot create but can view Manage',
    { tags: '@high' },
    () => {
      let collectionurl;
      // Manager can create collection
      cy.login('manager');
      navigateToManageContent();
      collectionPage.createCollection({
        title: collectionNameManager,
        contactEmail: 'manager@example.com',
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
      cy.intercept('POST', '/admin/collections/*').as(
        'updateCollectionManager'
      );
      cy.get('input[name="add_depositor_display"]')
        .type(Cypress.env('USERS_USER_USERNAME'))
        .should('have.value', Cypress.env('USERS_USER_USERNAME'));
      cy.get('.tt-menu .tt-suggestion')
        .should('be.visible')
        .and('contain', Cypress.env('USERS_USER_USERNAME'))
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
    }
  );

  it(
    "Verify editing item discovery - Checking the Hide this item from search results for new items in the collection -'@Tf7cefb09 ",
    { tags: '@high' },
    () => {
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

          cy.visit('/media_objects/' + item_id_discovery);
        });

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
          item_title_discovery
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
          item_title_discovery
        ).should('exist');
      });

      //user
      cy.login('user');
      homePage.getBrowseNavButton();
      performSearch(item_title_discovery);

      cy.get('[data-testid="browse-results-list"]').within(() => {
        cy.contains(
          '[data-testid^="browse-document-title-"]',
          item_title_discovery
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
            'No items visible in browse results — skipping title assertion.'
          );
        }
      });
    }
  );

  it(
    "Verify editing item discovery - Checking the Hide this item from search results for existing items in the collection -'@Tf7cefb09 ",
    { tags: '@high' },
    () => {
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
          item_title_discovery
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
          item_title_discovery
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
          item_title_discovery
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
            'No items visible in browse results — skipping title assertion.'
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
            'No items visible in browse results — skipping title assertion.'
          );
        }
      });
    }
  );

  it(
    'Verify adding Avalon user in assign special access for a user/ Setting default access control for new item - Verify assigning special access to an avalon user',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      //adding normal user in assign access for a user
      cy.get('[data-testid="media-object-user"]')
        .eq(1)
        .type(Cypress.env('USERS_USER_USERNAME'))
        .should('have.value', Cypress.env('USERS_USER_USERNAME'));
      cy.get('.tt-menu .tt-suggestion')
        .should('be.visible')
        .and('contain', Cypress.env('USERS_USER_USERNAME'))
        .click();
      cy.get('[data-testid="submit-add-user"]').click();

      //creating a new item
      item_title = `Automation Item title ${
        Math.floor(Math.random() * 100000) + 1
      }`;

      collectionPage.createItem(item_title, 'test_sample.mp4').then((id) => {
        item_id = id;
        createdItemIds.push(id);
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
        cy.visit('/users/sign_out');

        //Checking if the user can now access the item
        cy.login('user');
        cy.visit('/media_objects/' + item_id);
      });
    }
  );

  it(
    'Apply to all existing items - Verify assigning special access : Verify assigning special access to an avalon user',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      //adding normal user in assign access for a user
      cy.get('[data-testid="media-object-user"]')
        .eq(1)
        .type(Cypress.env('USERS_USER_USERNAME'))
        .should('have.value', Cypress.env('USERS_USER_USERNAME'));
      cy.get('.tt-menu .tt-suggestion')
        .should('be.visible')
        .and('contain', Cypress.env('USERS_USER_USERNAME'))
        .click();
      cy.get('[data-testid="submit-add-user"]').click();
      //click on apply to all existing items
      cy.get('[data-testid="collection-apply-to-all-btn-spl-access"]').click();

      // Checking access with the user for all the existing items

      cy.login('user');
      createdItemIds.forEach((itemId) => {
        cy.wrap(createdItemIds).each((itemId) => {
          cy.log(`Verifying public access for item: ${itemId}`);
          cy.visit('/media_objects/' + itemId);
        });
      });
    }
  );

  it(
    'Verify removing a user/group/ip address assigned for special access in the collection',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      // Removing the user from the special access
      collectionPage.navigateToCollection(collection_title);
      cy.get('[data-testid="collection-access-label-user"]').contains(
        Cypress.env('USERS_USER_USERNAME')
      );
      cy.get('[data-testid="collection-access-remove-user"]').click();
      //Checking for newly created items
      //creating a new item
      var item_title_no_spl_access = `Automation Item title ${
        Math.floor(Math.random() * 100000) + 1
      }`;
      var item_id_no_spl_access;
      collectionPage
        .createItem(item_title_no_spl_access, 'test_sample.mp4')
        .then((id) => {
          item_id_no_spl_access = id;
          createdItemIds.push(id);
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
          cy.visit('/users/sign_out');

          //Checking if the user can now access the item
          cy.login('user');
          cy.intercept('GET', '/media_objects/*').as('getmediaobject');
          cy.visit('/media_objects/' + item_id_no_spl_access, {
            failOnStatusCode: false,
          });
          cy.wait('@getmediaobject').then((interception) => {
            expect(interception.response.statusCode).to.eq(401);
          });
        });

      //checking access for the existing items - it should be there.

      cy.wrap(createdItemIds).each((itemId) => {
        if (itemId !== item_id_no_spl_access) {
          cy.log(`Verifying public access for item: ${itemId}`);
          cy.visit('/media_objects/' + itemId);
        } else {
          cy.log(`Skipping item: ${itemId} (matches item_title_discovery)`);
        }
      });

      //clicking on apply to existing items
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.get('[data-testid="collection-apply-to-all-btn-spl-access"]').click();
      cy.get(
        '[data-testid="collection-replace-exiting-special-access-chkbox"]'
      ).click();
      cy.get('[data-testid="collection-modal-footer"]').within(() => {
        cy.get('[data-testid="collection-apply-to-existing-btn"]').click();
      });

      cy.wait(5000);
      //checking for existing items - access should be revoked for the user
      cy.login('user');

      cy.wrap(createdItemIds).each((itemId) => {
        cy.log(`Verifying public access for item: ${itemId}`);
        cy.request({
          url: '/media_objects/' + itemId,
          failOnStatusCode: false,
        }).then((resp) => {
          expect(resp.status).to.eq(401);
        });
      });
    }
  );

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
        collection_title
      );
    }
  );

  it(
    'Verify changing item access - Collection staff only (New items) - @T9978b4f7 ',
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
    }
  );

  it(
    'Verify changing item access - Collection staff only (Existing items) - @Tdcf756bd',
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
      //need to add validation for exiting items and newly created items
    }
  );

  it(
    'Setting default access control for new item - Verify changing item access - Available to the general public',
    { tags: '@high' },
    () => {
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

          cy.visit('/media_objects/' + item_id_general_public);
          //check with normal user if they can access
          itemPage.verifyGeneralPublicAccess(item_id_general_public);
        });
    }
  );

  it(
    'Apply to all existing items - Verify changing item access - Available to the general public',
    { tags: '@high' },
    () => {
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
          '/admin/collections/'
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
    }
  );

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
          'updateCollectionInfo'
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
            updatedDescription
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
          'test1@mail.com'
        );
        cy.get("[data-testid='collection-description']").should(
          'contain.text',
          updatedDescription
        );
      });
    }
  );

  it(
    'Verify whether a user is able to update poster image -  @T26526b2e ',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.intercept('POST', '**/poster').as('updatePoster');
      cy.get("[data-testid='collection-poster-input']").selectFile(
        getFixturePath('image.png'),
        { force: true }
      );
      cy.wait(5000);
      cy.screenshot();
      cy.get("[data-testid='collection-upload-poster']").click();
      cy.wait('@updatePoster').its('response.statusCode').should('eq', 302);
      cy.get("[data-testid='alert']")
        .contains('Poster file successfully added.')
        .should('be.visible');
    }
  );
  it(
    'Verify limiting the items by Published status - @T26526b2e',
    { tags: '@high' },
    () => {
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
                `Facet: ${trimmedFacetCount} | Result: ${resultCount.trim()}`
              );
              expect(trimmedFacetCount).to.eq(resultCount.trim());
            });

          //  Click on the first result
          cy.get('[data-testid^="browse-document-title-"]').first().click();

          // Validate you're on the detail page and see the Unpublish button
          cy.url().should('include', '/media_objects/');
          cy.waitForVideoReady();
          cy.get('[data-testid="media-object-unpublish-btn"]').should(
            'be.visible'
          );
        });
    }
  );
});
