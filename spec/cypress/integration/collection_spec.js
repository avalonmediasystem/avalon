import HomePage from '../pageObjects/homePage.js';
import CollectionPage from '../pageObjects/collectionPage';
import {
  navigateToManageContent,
  selectCollectionUnit,
} from '../support/navigation.js';

const collectionPage = new CollectionPage();
const homePage = new HomePage();
context('Collections Test', () => {
  //Admin created collection
  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;

  //Collection name created by manager
  const collectionNameManager = `Automation collection title - manager${
    Math.floor(Math.random() * 10000) + 1
  }`;
  var item_title; //This is an item under collection created by admin
  var item_id;

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
    if (item_id) {
      collectionPage.deleteItemById(item_id);
    }

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
    'Verify adding Avalon user in assign special access for a user',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      collectionPage.navigateToCollection(collection_title);
      cy.get('[data-testid="media-object-user"]')
        .eq(1)
        .type(Cypress.env('USERS_USER_USERNAME'))
        .should('have.value', Cypress.env('USERS_USER_USERNAME'));
      cy.get('.tt-menu .tt-suggestion')
        .should('be.visible')
        .and('contain', Cypress.env('USERS_USER_USERNAME'))
        .click();
      cy.get('[data-testid="submit-add-user"]').click();
    }
  );

  it('Creates an item under a collection', { tags: '@critical' }, () => {
    cy.login('administrator');
    item_title = `Automation Item title ${
      Math.floor(Math.random() * 100000) + 1
    }`;
    collectionPage.navigateToCollection(collection_title);
    collectionPage.createItem(item_title, 'test_sample.mp4').then((id) => {
      item_id = id;
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
      cy.login('user');
      cy.visit('/media_objects/' + item_id);
    });
  });

  it(
    "Verify whether the user is able to search for Collections-'@Tf7cefb09 ",
    { tags: '@critical' },
    () => {
      cy.login('administrator');
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
        'spec/cypress/fixtures/image.png',
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
});
