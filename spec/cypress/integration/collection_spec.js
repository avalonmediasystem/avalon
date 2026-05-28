import HomePage from '../pageObjects/homePage';
import CollectionPage from '../pageObjects/collectionPage';
import ItemPage from '../pageObjects/itemPage';
import { getFixturePath } from '../support/utils';
import UnitPage from '../pageObjects/unitPage';

import {
  navigateToManageContent,
  selectCollectionUnit,
  performSearch,
  verifySearchable,
  verifyUnsearchable
} from '../support/navigation.js';

const collectionPage = new CollectionPage();
const homePage = new HomePage();
const itemPage = new ItemPage();
const unitPage = new UnitPage();
context('Collections Test', () => {
  var unit_title = `Automation unit title ${ Date.now() }`;
  //Admin created collection
  var collection_title = `Automation collection title ${ Date.now() }`;
  var item_title_basic = `Automation item title ${ Date.now() }`;
  let item_id_basic;

  //Collection name created by manager
  const collectionNameManager = `Automation collection title - manager${ Date.now() }`;
  let createdItemIds = [];
  let createdCollections = [];


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
    navigateToManageContent();
    collectionPage.createCollection({ title: collection_title, unitName: unit_title });
    collectionPage.createItem(item_title_basic, 'test_sample.mp4', { publish: true }).then((id) => {
      item_id_basic = id;
      createdItemIds.push(item_id_basic);
    });
  });

  // Cleanup after all tests
  after(() => {
    cy.login('administrator');

    // Delete item first
    createdItemIds.forEach((id) => {
      collectionPage.deleteItemById(id);
    });

    // Delete manager collection
    createdCollections.forEach((name) => {
      collectionPage.deleteCollectionByName(name);
    });

    // Delete main collection
    collectionPage.deleteCollectionByName(collection_title);

    // Delete unit
    unitPage.deleteUnitByName(unit_title);
  });

  it(
    'Verify whether an admin user is able to create a collection - @T553cda51 ',
    { tags: '@critical' },
    () => {
      // no-op
      // All of the parts of this test are handled in before()
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
      collectionPage.addManager(Cypress.env('USERS_MANAGER_USERNAME'));
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

    //TODO: Check the manager isn't already in collection before doing this
    collectionPage.addManager(Cypress.env('USERS_MANAGER_USERNAME'));

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
    //FIXME can fail if lingering units/collections grant this user privileges to manage content
    cy.contains('Manage').should('not.exist');

    //adding the manager back again for rest of the test cases
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    collectionPage.addManager(Cypress.env('USERS_MANAGER_USERNAME'));
  });

  it('Verify that only the admins and unit admins can create a collection - @T680b0e35', () => {
    let collectionurl;
    // Unit admin can create collection
    cy.login('unit_admin');
    navigateToManageContent();

    collectionPage.createCollection({
      title: collectionNameManager,
      contactEmail: 'manager@example.com',
      unitName: unit_title,
    });
    createdCollections.push(collectionNameManager);
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

  it('Verify editing item discovery - Checking the Hide this item from search results for items in the collection - @T7108664f @T126023f1 @T234440d9', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    collectionPage.setAccess('public');
    collectionPage.setHidden(true);
    verifySearchable(item_id_basic, item_title_basic);

    //user
    cy.login('user');
    homePage.getBrowseNavButton();
    verifyUnsearchable(item_id_basic, item_title_basic);

    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    collectionPage.setHidden(false);
    verifySearchable(item_id_basic, item_title_basic);

    //user
    cy.login('user');
    homePage.getBrowseNavButton();
    verifySearchable(item_id_basic, item_title_basic);
  });

  it(
    'Verify adding Avalon user in assign special access for a user - @T553cda51 @T2a81c8fd',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      //pre condition - setting the collection item access to be collection staff only so that we can verify the special access functionality
      collectionPage.setAccess('private');
      collectionPage.addSpecialAccessUser(Cypress.env('USERS_USER_USERNAME'));

      // Verify user can access default item
      cy.login('user');
      itemPage.verifyAccessible(item_id_basic);
    },
  );

  it('Verify removing a user/group/ip address assigned for special access in the collection - @T6b4b1eab', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    collectionPage.addSpecialAccessUser(Cypress.env('USERS_USER_USERNAME'));

    // Remove user from special access
    cy.intercept('POST', '/admin/collections/*').as('updateSpecialAccess');
    cy.get('[data-testid="collection-access-remove-user"]').click();
    cy.wait('@updateSpecialAccess')
      .its('response.statusCode')
      .should('eq', 302);

    // Verify existing items are no longer accessible to user after removal
    cy.login('user');
    itemPage.verifyInaccessible(item_id_basic);
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
    'Setting default access control for new item - Verify changing item access - Collection staff only  - @T9978b4f7 ; Inherited - Verify changing item access - Collection staff only - @Tdcf756bd',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      collectionPage.setAccess('private');
      itemPage.verifyCollecttionStaffAccess(item_id_basic);
    },
  );

  it('Setting default access control for new item - Verify changing item access - Logged in users only ; Inherited - Verify changing item access - Logged in users only', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    collectionPage.setAccess('logged-in');
    itemPage.verifyLoggedInUserAccess(item_id_basic);
  });

  it('Setting default access control for new item - Verify changing item access - Available to the general public - @Tcc0080ba ; Inherited - Verify changing item access - Available to the general public - @T906c672e', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);
    collectionPage.setAccess('public');
    itemPage.verifyGeneralPublicAccess(item_id_basic);
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
      var new_title = `Updated automation title ${ Date.now() }`;
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
      });
  });
  it(
    'delete a collection in after block - critical test case - @T959a56df and @T0e0a5611',
    { tags: '@critical' },
    () => {
      // Handled in after()
  });
});
