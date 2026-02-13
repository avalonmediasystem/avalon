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
Cypress.config();

context('Unit Framework', () => {
  //Unit title
  var unit_title = `Automation unit title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  //Create collection title
  var collection_title = `Automation collection title ${
    Math.floor(Math.random() * 10000) + 1
  }`;
  //unit title
  var item_title = `Automation Item title ${
    Math.floor(Math.random() * 100000) + 1
  }`;

  //users from env files
  const admin = Cypress.env('USERS_ADMINISTRATOR_EMAIL');
  const user = Cypress.env('USERS_USER_EMAIL');
  const manager = Cypress.env('USERS_MANAGER_EMAIL');
  const unit_admin = Cypress.env('USERS_UNITADMIN_EMAIL');
  const unit_manager = Cypress.env('USERS_UNITMANAGER_EMAIL');

  let item_id;
  let createdItems = []; // Track all created items for cleanup

  // Create collection before all tests
  before(() => {
    cy.login('administrator');
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
  //1.
  it('Verify that only the admins can see create unit button', () => {
    cy.login('administrator');
    navigateToManageContent();
    // admin should see the create unit button
    cy.get('[data-testid="unit-create-unit-button"]').should('be.visible');
    cy.logout();
    cy.login('manager');
    // manager should not see the create unit button
    cy.get('[data-testid="unit-create-unit-button"]').should('not.exist');
    cy.logout();
    cy.login('user');
    // user should not see the create unit button
    cy.get('[data-testid="unit-create-unit-button"]').should('not.exist');
  });
  //2.
  it('Verify that only the admins can create units', () => {
    cy.login('administrator');
    navigateToManageContent();
    cy.get('[data-testid="unit-create-unit-button"]')
      .should('be.visible')
      .click();
    cy.get('[data-testid="unit-title-input"]').type(unit_title);
    cy.get('[data-testid="unit-description"]').type(
      'Automation Unit Description'
    );
    cy.get('[data-testid="unit-contact-email"]').type(
      'administrator@example.com'
    );
    cy.get('[data-testid="unit-website-url"]').type('http://www.example.com');
    cy.get('[data-testid="unit-website-label"]').type('Website label');
    cy.get('[data-testid="unit-new-unit-btn"]').click();
    cy.get('[data-testid="alert"]').contains('unit was successfully created.'); //might need to change this alert later
    //Validate that the unit details are correct
    cy.get('[data-testid="unit-unit-details"]').contains(unit_title);
    cy.get('[data-testid="unit-description"]').contains(
      'Automation Unit Description'
    );
    cy.get('[data-testid="unit-contact-email"]').contains(
      'administrator@example.com'
    );
    cy.get('[data-testid="unit-website-url"]')
      .should('be.visible')
      .and('have.attr', 'href', 'http://www.example.com')
      .and('contain.text', 'Website label');
  });
  //Unit admin should be added by default
  cy.get('[data-testid="collection-access-label-unit_admin"]')
    .should('be.visible')
    .and('contain.text', admin);
  //Buttons should be visible to admin
  cy.get('[data-testid="unit-create-item-btn"]').should('be.visible');
  cy.get('[data-testid="unit-list-collections-btn"]').should('be.visible');
  cy.get('[data-testid="unit-edit-unit-info"]').should('be.visible');
  //Collextion staff only by default
  cy.get('[data-testid="unit-checkbox-unit-staff"]').should('be.checked');
});
//3.
it('Verify editing unit information', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  cy.get('[data-testid="unit-edit-unit-info"]').should('be.visible').click();
  //title
  new_unit_title = `Updated ${unit_title}`;
  cy.get('[data-testid="unit-update-name"]')
    .should('have.value', unit_title)
    .clear()
    .type(new_unit_title)
    .should('have.value', new_unit_title);
  //description
  cy.get('[data-testid="unit-update-description"]')
    .should('have.value', 'Automation Unit Description')
    .clear()
    .type('Updated Automation Unit Description')
    .should('have.value', 'Updated Automation Unit Description');
  //contact email
  cy.get('[data-testid="unit-update-contact-email"]')
    .should('have.value', 'administrator@example.com')
    .clear()
    .type('updated@example.com')
    .should('have.value', 'updated@example.com');

  cy.get('[data-testid="unit-update-unit-btn"]').click();
  // no alert for update for now
  cy.get('[data-testid="unit-unit-details"]').contains(newUnitTitle);
  cy.get('[data-testid="unit-description"]').contains(
    'Updated Automation Unit Description'
  );
  cy.get('[data-testid="unit-contact-email"]').contains('updated@example.com');
  //Updatting unit title
  unit_title = new_unit_title;
});

//4.
it('Verify whether the user is able to upload poster image.', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
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
});

//5.
it('Verify whether the user is able to remove poster image.', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  cy.intercept('POST', '**/poster').as('updatePoster');
  cy.get("[data-testid='unit-poster-input']").selectFile(
    getFixturePath('image.png'),
    { force: true }
  );
  cy.wait(5000);
  cy.screenshot();
  cy.get("[data-testid='unit-upload-poster']").click();
  cy.wait('@updatePoster').its('response.statusCode').should('eq', 302);
  cy.get("[data-testid='alert']")
    .contains('Poster file successfully added.')
    .should('be.visible');
  cy.get('[data-testid="unit-poster-image"]')
    .should('be.visible')
    .and('have.attr', 'src')
    .and('include', '/admin/units/')
    .and('include', '/poster');
});

//6.
it('Verify whether the user is able to remove poster image.', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  cy.get('[data-testid="unit-remove-poster-btn"]')
    .should('have.value', 'Remove Poster')
    .click();
  //poster is removed and src attribute is gone
  cy.get('[data-testid="unit-poster-image"]').should('not.have.attr', 'src');
  cy.get("[data-testid='alert']")
    .contains('Poster file successfully removed.')
    .should('be.visible');
});

//7.
it('Verify creating collection on manage unit.', () => {
  //Creating this through admin but can be craeted through manager role as well
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  cy.get('[data-testid="unit-create-collection-btn"]')
    .should('be.visible')
    .click();
  // fill out collection form - name, unit and description
  cy.get('[data-testid="collection-name"]').type(collection_title);
  cy.get('[data-testid="admin_collection[unit_name]-user-input"]').type(
    unit_title
  );
  //unit should appear in the popup
  cy.get('[data-testid="admin_collection[unit_name]-popup"]')
    .should('be.visible')
    .and('contain.text', unit_title)
    .click();
  cy.get('[data-testid="collection-description"]').type(
    'Automation collection description'
  );
  cy.get('[data-testid="collection-new-collection-btn"]').click();
  //validate collection creation
  cy.get('[data-testid="alert"]')
    .contains('Collection was successfully created.')
    .should('be.visible');
  //validate collection details
  cy.get('[data-testid="collection-title"]').contains(collection_title);
  cy.get('[data-testid="collection-unit"]').contains(unit_title);
  cy.get('[data-testid="collection-description"]').contains(
    'Automation collection description'
  );
  //unit admin should be inherited as collection manager
  cy.get('[data-testid="collection-access-label-manager"]')
    .should('be.visible')
    .and('contain.text', 'administrator@example.com')
    .and(
      'contain.text',
      'This role is inherited from Unit "' +
        unit_title +
        '" and cannot be removed.'
    );
  //collection staff should be inherited from unit
  cy.get('[data-testid="collection-checkbox-collection-staff"]').should(
    'be.checked'
  );
  //valiadting that the collection number is updated on unit table under manage content page
  navigateToManageContent();
  cy.get('[data-testid="unit-name-table"]')
    .contains(unit_title)
    .closest('tr')
    .find('[data-testid="unit-collections-count"]')
    .should('have.text', '1 collection');
});

//8.
it('Verify all the list of all the related collections of an unit', () => {
  cy.login('administrator');
  // we need to craete an item before listing the collection
  collectionPage.navigateToCollection(collection_title);
  collectionPage.createItem(item_title, 'test_sample.mp4').then((id) => {
    createdItemIds.push(id);
    cy.get('[data-testid="media-object-publish-btn"]')
      .contains('Publish')
      .click();
    cy.get('[data-testid="alert"]').contains(
      '1 media object successfully published.'
    );
    cy.wait(5000);
    cy.get('[data-testid="media-object-unpublish-btn"]').contains('Unpublish');
  });
  //Now navigate to unit page and list collections
  unitPage.navigateToUnit(unit_title);
  cy.get('[data-testid="unit-list-collections-btn"]')
    .should('be.visible')
    .click();
  //url check
  cy.url().should(
    'include',
    '/collections?filter=' + encodeURIComponent(unit_title)
  );
  //input check
  cy.get('[data-testid="collection-search-collection-input"]')
    .should('have.value', unit_title)
    .should('be.visible');
  //collection card check
  cy.get('[data-testid="collection-card-body"]')
    .find('a')
    .contains(collection_title)
    .click();
  //validate the collection has item card created above
  cy.get('[data-testid="collection-card-body"]').find('a').contains(item_title);
});
//9. we need to create a new user for this test and assign admin rol
it('Assign Staff Roles: Verify the user is able to add an user as an unit administrator.', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  //checking the default admin user is present
  cy.get('[data-testid="collection-access-label-unit_admin"]').contains(admin);
  //add new unit admin
  cy.get('[data-testid="unit-add-admin-input"]')
    .type(unit_admin)
    .should('have.value', unit_admin);
  cy.get('[data-testid="add_unit_admin-popup"]')
    .should('be.visible')
    .contains('li[role="option"] span', unit_admin)
    .click();
  cy.get('[data-testid="submit-add-unit_admin"]').click();
  //validate
  cy.get('[data-testid="collection-access-label-unit_admin"]')
    .contains('label', unit_admin)
    .should('be.visible');
  //logout and login with new unit admin and validate access
  cy.logout();
  cy.login('unit_admin');
  unitPage.navigateToUnit(unit_title);
  cy.get('[data-testid=""unit-unit-details"]')
    .contains(unit_title)
    .should('be.visible');
  //validate that the collection has inherited the new unit admin as collection manager
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="collection-access-label-manager"]')
    .should('be.visible')
    .and('contain.text', unit_admin)
    .and(
      'contain.text',
      'This role is inherited from Unit "' +
        unit_title +
        '" and cannot be removed.'
    );
  // should we validate the item access
});
//10.
it('Assign Staff Roles: Verify removing user from unit admin field', () => {
  cy.login('administrator');
  //verify unit admin is present
  cy.get('[data-testid="collection-access-label-unit_admin"]')
    .contains('label', unit_admin)
    .should('be.visible');
  //remove unit admin
  cy.get('[data-testid="collection-access-label-unit_admin"]')
    .contains('label', unit_admin)
    .closest('tr')
    .find('[data-testid="collection-access-remove-unit_admin"]')
    .click();
  //validate
  cy.get('[data-testid="collection-access-label-unit_admin"]')
    .contains('label', unit_admin)
    .should('not.exist');
  //inherited in collection should be removed as well
  cy.login('unitadmin');
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="collection-access-label-manager"]').should('not.exist');
});
//11.
it('Assign Staff Roles: Verify the user is able to add an user as a manager', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  //adding the new manager

  cy.get('[data-testid="add_manager-user-input"]')
    .type(unit_manager)
    .should('have.value', unit_manager);
  cy.get('[data-testid="add_manager-popup"]')
    .should('be.visible')
    .contains('li[role="option"] span', unit_manager)
    .click();
  cy.get('[data-testid="submit-add-manager"]').click();
  //validate
  cy.get('[data-testid="collection-access-label-manager"]')
    .contains('label', unit_manager)
    .should('be.visible');
  //logout and login with new manager and validate access
  cy.logout();
  cy.login('unit_manager');
  unitPage.navigateToUnit(unit_title);
  //title visible to manager
  cy.get('[data-testid=""unit-unit-details"]')
    .contains(unit_title)
    .should('be.visible');
  //add admin and manager buttons should be disabled for manager
  cy.get('[data-testid="submit-add-unit_admin"]').should('be.disabled');
  cy.get('[data-testid="submit-add-manager"]').should('be.disabled');
  cy.get('[data-testid="submit-add-user"]').should('be.disabled');
  cy.get('[data-testid="submit-add-group"]').should('be.disabled');
  cy.get('[data-testid="submit-add-class"]').should('be.disabled');
  cy.get('[data-testid="submit-add-ipaddress"]').should('be.disabled');
  //editor and depositer add button should be enabled for manager
  cy.get('[data-testid="submit-add-editor"]').should('be.enabled');
  cy.get('[data-testid="submit-add-depositor"]').should('be.enabled');
  //discovery and access is read only for manager
  cy.get('[data-testid="unit-item-discovery"]').contains(
    'Item is not hidden from search results'
  );
  cy.get('[data-testid="unit-item-access"]').contains(
    'Item is viewable by unit staff only'
  );
  //validate that the collection has inherited the new manager as collection manager
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="collection-access-label-manager"]')
    .should('be.visible')
    .and('contain.text', unit_manager)
    .and(
      'contain.text',
      'This role is inherited from Unit "' +
        unit_title +
        '" and cannot be removed.'
    );
});
//12
it('Assign Staff Roles: Verify removing user from manager field', () => {
  cy.login('administrator');
  //add one manager as it won't allow to remove the manager role if it's the only manager present
  cy.get('[data-testid="add_manager-user-input"]')
    .type(manager)
    .should('have.value', manager);
  cy.get('[data-testid="add_manager-popup"]')
    .should('be.visible')
    .contains('li[role="option"] span', manager)
    .click();
  cy.get('[data-testid="submit-add-manager"]').click();
  //verify manager is present
  cy.get('[data-testid="collection-access-label-manager"]')
    .contains('label', unit_manager)
    .should('be.visible');
  //remove manager
  cy.get('[data-testid="collection-access-label-manager"]')
    .contains('label', unit_manager)
    .closest('tr')
    .find('[data-testid="collection-access-remove-manager"]')
    .click();
  //validate
  cy.get('[data-testid="collection-access-label-manager"]')
    .contains('label', unit_manager)
    .should('not.exist');
  //inherited in collection should be removed as well
  cy.login('unit_manager');
  navigateToManageContent();
  cy.get('body').then(($body) => {
    if ($body.find('[data-testid="unit-name-table"]').length) {
      cy.get('[data-testid="unit-name-table"]').should(
        'not.contain',
        unit_title
      );
      cy.get('[data-testid="collection-name-table"]').should(
        'not.contain',
        collection_title
      );
    } else {
      cy.contains('h2', "You don't have any units yet").should('be.visible');
      cy.contains('p', "You'll need to be assigned to one").should(
        'be.visible'
      );
    }
  });
});
//13.
it('Assign Staff Roles: Verify the user is able to add an user as an editor', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  //adding the new editor
  cy.get('[data-testid="add_editor-user-input"]')
    .type(user)
    .should('have.value', user);
  cy.get('[data-testid="add_editor-popup"]')
    .should('be.visible')
    .contains('li[role="option"] span', user)
    .click();
  cy.get('[data-testid="submit-add-editor"]').click();
  //validate
  cy.get('[data-testid="collection-access-label-editor"]')
    .contains('label', user)
    .should('be.visible');
  //logout and login with new editor and validate access
  cy.logout();
  cy.login('user');
  unitPage.navigateToUnit(unit_title);
  //title visible to editor
  cy.get('[data-testid="unit-unit-details"]')
    .contains(unit_title)
    .should('be.visible');
  //add admin and manager buttons should be disabled for editor
  cy.get('[data-testid="submit-add-unit_admin"]').should('be.disabled');
  cy.get('[data-testid="submit-add-manager"]').should('be.disabled');
  cy.get('[data-testid="submit-add-editor"]').should('be.disabled');
  cy.get('[data-testid="submit-add-user"]').should('be.disabled');
  cy.get('[data-testid="submit-add-group"]').should('be.disabled');
  cy.get('[data-testid="submit-add-class"]').should('be.disabled');
  cy.get('[data-testid="submit-add-ipaddress"]').should('be.disabled');
  //depositor add button should be disabled for editor
  cy.get('[data-testid="submit-add-depositor"]').should('be.enabled');
  //discovery and access is read only for editor
  cy.get('[data-testid="unit-item-discovery"]').contains(
    'Item is not hidden from search results'
  );
  cy.get('[data-testid="unit-item-access"]').contains(
    'Item is viewable by unit staff only'
  );
  //validate that the collection has inherited the new editor as collection editor
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="collection-access-label-editor"]')
    .should('be.visible')
    .and('contain.text', user)
    .and(
      'contain.text',
      'This role is inherited from Unit "' +
        unit_title +
        '" and cannot be removed.'
    );
});
//14.
it('Assign Staff Roles: Verify removing user from editor field', () => {
  cy.login('administrator');
  //verify editor is present
  cy.get('[data-testid="collection-access-label-editor"]')
    .contains('label', user)
    .should('be.visible');
  //remove editor
  cy.get('[data-testid="collection-access-label-editor"]')
    .contains('label', user)
    .closest('tr')
    .find('[data-testid="collection-access-remove-editor"]')
    .click();
  //validate
  cy.get('[data-testid="collection-access-label-editor"]')
    .contains('label', user)
    .should('not.exist');
  //inherited in collection should be removed as well
  cy.login('user');
  navigateToManageContent();
  cy.get('body').then(($body) => {
    if ($body.find('[data-testid="unit-name-table"]').length) {
      cy.get('[data-testid="unit-name-table"]').should(
        'not.contain',
        unit_title
      );
      cy.get('[data-testid="collection-name-table"]').should(
        'not.contain',
        collection_title
      );
    } else {
      cy.contains('h2', "You don't have any units yet").should('be.visible');
      cy.contains('p', "You'll need to be assigned to one").should(
        'be.visible'
      );
    }
  });
});

//15.
it('Assign Staff Roles: Verify the user is able to add an user as a depositor.', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  //adding the new depositor
  cy.get('[data-testid="add_depositor-user-input"]')
    .type(user)
    .should('have.value', user);
  cy.get('[data-testid="add_depositor-popup"]')
    .should('be.visible')
    .contains('li[role="option"] span', user)
    .click();
  cy.get('[data-testid="submit-add-depositor"]').click();
  //validate
  cy.get('[data-testid="collection-access-label-depositor"]')
    .contains('label', user)
    .should('be.visible');
  //logout and login with new depositor and validate access
  cy.logout();
  cy.login('user');
  unitPage.navigateToUnit(unit_title);
  //title visible to depositor
  cy.get('[data-testid="unit-unit-details"]')
    .contains(unit_title)
    .should('be.visible');
  //add admin, manager and editor buttons should be disabled for depositor
  cy.get('[data-testid="submit-add-unit_admin"]').should('be.disabled');
  cy.get('[data-testid="submit-add-manager"]').should('be.disabled');
  cy.get('[data-testid="submit-add-editor"]').should('be.disabled');
  cy.get('[data-testid="submit-add-depositor"]').should('be.disabled');
  cy.get('[data-testid="submit-add-user"]').should('be.disabled');
  cy.get('[data-testid="submit-add-group"]').should('be.disabled');
  cy.get('[data-testid="submit-add-class"]').should('be.disabled');
  cy.get('[data-testid="submit-add-ipaddress"]').should('be.disabled');
  //discovery and access is read only for depositor
  cy.get('[data-testid="unit-item-discovery"]').contains(
    'Item is not hidden from search results'
  );
  cy.get('[data-testid="unit-item-access"]').contains(
    'Item is viewable by unit staff only'
  );
  //validate that the collection has inherited the new depositor as collection depositor
  collectionPage.navigateToCollection(collection_title);
  cy.get('[data-testid="collection-access-label-depositor"]')
    .should('be.visible')
    .and('contain.text', user)
    .and(
      'contain.text',
      'This role is inherited from Unit "' +
        unit_title +
        '" and cannot be removed.'
    );
});
//16
it('Assign Staff Roles: Verify removing user from depositor field', () => {
  cy.login('administrator');
  //verify depositor is present
  cy.get('[data-testid="collection-access-label-depositor"]')
    .contains('label', user)
    .should('be.visible');
  //remove depositor
  cy.get('[data-testid="collection-access-label-depositor"]')
    .contains('label', user)
    .closest('tr')
    .find('[data-testid="collection-access-remove-depositor"]')
    .click();
  //validate
  cy.get('[data-testid="collection-access-label-depositor"]')
    .contains('label', user)
    .should('not.exist');
  //inherited in collection should be removed as well
  cy.login('user');
  navigateToManageContent();
  cy.get('body').then(($body) => {
    if ($body.find('[data-testid="unit-name-table"]').length) {
      cy.get('[data-testid="unit-name-table"]').should(
        'not.contain',
        unit_title
      );
      cy.get('[data-testid="collection-name-table"]').should(
        'not.contain',
        collection_title
      );
    } else {
      cy.contains('h2', "You don't have any units yet").should('be.visible');
      cy.contains('p', "You'll need to be assigned to one").should(
        'be.visible'
      );
    }
  });
});
//17
it('Assign Staff Roles: Verify that users with manager role cannot be added as an unit administrator', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  //add manager
  cy.get('[data-testid="unit-add-admin-input"]')
    .type(manager)
    .should('have.value', manager);
  cy.get('[data-testid="add_unit_admin-popup"]')
    .should('be.visible')
    .contains('li[role="option"] span', manager)
    .click();
  cy.get('[data-testid="submit-add-unit_admin"]').click();
  //validate
  cy.get('[data-testid="alert"]').contains(
    'User ' + manager + ' does not belong to the unit administrator group.'
  );
  //log in as manager and validate that the unit is not seeable
  cy.logout();
  cy.login('manager');
  navigateToManageContent();
  cy.get('[data-testid="unit-name-table"]').should('not.contain', unit_title);
});
//18
it('Assign Staff Roles: Verify that users without manager/admin role cannot be added as a manager', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  //adding user without manager role as manager
  cy.get('[data-testid="add_manager-user-input"]')
    .type(user)
    .should('have.value', user);
  cy.get('[data-testid="add_manager-popup"]')
    .should('be.visible')
    .contains('li[role="option"] span', user)
    .click();
  cy.get('[data-testid="submit-add-manager"]').click();
  //validate
  cy.get('[data-testid="alert"]').contains(
    'User ' + user + ' does not belong to the manager group.'
  );
  //log in as manager and validate that the unit is not seeable
  cy.logout();
  cy.login('user');
  navigateToManageContent();
  cy.get('[data-testid="unit-name-table"]').should('not.contain', unit_title);
});
//19
it('Assign Staff Roles: Verify that the only user in the Unit Admin field and Unit Manager field cannot be removed.', () => {
  cy.login('administrator');
  unitPage.navigateToUnit(unit_title);
  //verify admin is present
  cy.get('[data-testid="collection-access-label-unit_admin"]')
    .contains('label', admin)
    .should('be.visible');
  //try to remove the only unit admin
  cy.get('[data-testid="collection-access-label-unit_admin"]')
    .contains('label', admin)
    .closest('tr')
    .find('[data-testid="collection-access-remove-unit_admin"]')
    .click();
  //validate that the unit admin is not removed and error message is shown
  cy.get('[data-testid="collection-access-label-unit_admin"]')
    .contains('label', admin)
    .should('be.visible');
  cy.get('[data-testid="alert"]').contains(
    'At least one unit administrator is required.'
  );
  //verify manager is present
  cy.get('[data-testid="collection-access-label-manager"]')
    .contains('label', manager)
    .should('be.visible');
  //try to remove the only unit manager
  cy.get('[data-testid="collection-access-label-manager"]')
    .contains('label', manager)
    .closest('tr')
    .find('[data-testid="collection-access-remove-manager"]')
    .click();
  //validate that the unit manager is not removed and error message is shown
  cy.get('[data-testid="collection-access-label-manager"]')
    .contains('label', manager)
    .should('be.visible');
  cy.get('[data-testid="alert"]').contains('At least one manager is required.');
});
//20 delete unit
it('Deleting an Unit which has no child collections', () => {
  cy.login('administrator');
  //for now i am deleting it manually cause the reassignning collection is not implemented yet
  createdItems.forEach((id) => {
    if (id != item_id) collectionPage.deleteItemById(id);
  });
  // Then delete the collection
  collectionPage.deleteCollectionByName(collection_title);
  UnitPage.deleteUnitByName(unit_title);
  //validate unit is removed from manage content page
  navigateToManageContent();
  cy.get('[data-testid="unit-name-table"]').should('not.contain', unit_title);
});
//Item discovery, item access and assign special access are to be implemented
