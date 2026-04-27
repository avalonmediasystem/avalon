import HomePage from '../pageObjects/homePage';
import CollectionPage from '../pageObjects/collectionPage';
import ItemPage from '../pageObjects/itemPage';
import { getFixturePath } from '../support/utils';
import UnitPage from '../pageObjects/unitPage';

import {
  navigateToManageContent,
  selectCollectionUnit,
  performSearch,
} from '../support/navigation.js';

const collectionPage = new CollectionPage();
const homePage = new HomePage();
const itemPage = new ItemPage();
const unitPage = new UnitPage();
Cypress.config();

context('Unit Framework', () => {
  //Unit title
  var unit_title = `Automation unit title ${ Date.now() }`;
  //Create collection title
  var collection_title = `Automation collection title ${ Date.now() }`;
  //unit title
  var item_title = `Automation Item title ${ Date.now() }`;

  //users from env files
  const admin = Cypress.env('USERS_ADMINISTRATOR_EMAIL');
  const user = Cypress.env('USERS_USER_EMAIL');
  const manager = Cypress.env('USERS_MANAGER_EMAIL');
  const unit_admin = Cypress.env('USERS_UNITADMIN_EMAIL');
  const unit_manager = Cypress.env('USERS_UNITMANAGER_EMAIL');

  let createdItems = []; // Track all created items for cleanup

  // Create collection before all tests
  before(() => {
    cy.login('administrator');
    unitPage.createUnit(
      { title: unit_title, description: 'Automation Unit Description', contactEmail: 'administrator@example.com',
        websiteUrl: 'http://www.example.com', websiteLabel: 'Website Label' },
      {}
    );
    unitPage.createCollectionInUnit(unit_title, { title: collection_title }, {});
  });
  // cleaned up items on last test, this block can be used later to clean up
  // Clean up after all tests - ITEM FIRST, THEN COLLECTION
  after(() => {
    cy.login('administrator');
    createdItems.forEach((id) => {
      collectionPage.deleteItemById(id);
    });
    // Then delete the collection
    collectionPage.deleteCollectionByName(collection_title);
    // Delete unit
    unitPage.deleteUnitByName(unit_title);

    //validate unit is removed from manage content page
    navigateToManageContent();
    unitPage.verifyUnitNotAccessible(unit_title);
  });

  it('Verify that only the admins can see create unit button', () => {
    cy.login('administrator');
    navigateToManageContent();
    // admin should see the create unit button
    cy.get('[data-testid="unit-create-unit-button"]').should('be.visible');
    //homePage.logout();
    cy.login('unitmanager');
    navigateToManageContent();
    // manager should not see the create unit button
    cy.get('[data-testid="unit-create-unit-button"]').should('not.exist');
    //homePage.logout();
    cy.login('user');
    // user should not see the create unit button
    cy.contains('Manage').should('not.exist');
  });

  it('Verify unit defaults after creation', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);
    // Unit admin should be added by default
    cy.get('[data-testid="collection-access-label-unit_admin"]')
      .should('be.visible')
      .and('contain.text', admin);
    // Buttons should be visible to admin
    cy.get('[data-testid="unit-create-collection-btn"]').should('be.visible');
    cy.get('[data-testid="unit-list-collections-btn"]').should('be.visible');
    cy.get('[data-testid="unit-edit-unit-info"]').should('be.visible');
  });

  it('Verify editing unit information', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);
    cy.get('[data-testid="unit-edit-unit-info"]').should('be.visible').click();
    //title
    const new_unit_title = `Updated ${unit_title}`;
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
    cy.get('[data-testid="unit-unit-details"]').contains(new_unit_title);
    cy.get('[data-testid="unit-description"]').contains(
      'Updated Automation Unit Description'
    );
    cy.get('[data-testid="unit-contact-email"]').contains(
      'updated@example.com'
    );
    //Updatting unit title
    unit_title = new_unit_title;
  });

  it('Verify whether the user is able to upload poster image.', () => {
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
  });

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

  it('Verify whether the user is able to remove poster image.', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);
    cy.get('[data-testid="unit-remove-poster-btn"]')
      .should('have.value', 'Remove Poster')
      .click();
    //poster is removed and src attribute is gone
    cy.get('[data-testid="unit-poster-image"]').should('have.attr', 'src', '');
    cy.get("[data-testid='alert']")
      .contains('Poster file successfully removed.')
      .should('be.visible');
  });

  it('Verify creating collection on manage unit.', () => {
    cy.login('administrator');
    collectionPage.navigateToCollection(collection_title);

    //unit admin should be inherited as collection manager
    cy.get('[data-testid="collection-access-label-manager"]')
      .should('be.visible')
      .and('contain.text', 'administrator@example.com')
      .and(
        'contain.text',
        'This role is inherited and cannot be removed.'
      );
    //collection staff should be inherited from unit
    cy.get('[data-testid="collection-checkbox-collection-staff"]').should(
      'be.checked'
    );
    //valiadting that the collection number is updated on unit table under manage content page
    navigateToManageContent();
    cy.get('[data-testid="unit-table-search-field"]')
      .clear()
      .type(unit_title);
    cy.get("[data-testid='unit-name-table']")
      .contains(unit_title)
      .closest('tr')
      .find('[data-testid="unit-collections-count"]')
      .should('have.text', '1 collection');
  });

  it('Verify all the list of all the related collections of an unit', () => {
    cy.login('administrator');
    // we need to create an item before listing the collection
    collectionPage.navigateToCollection(collection_title);
    collectionPage.createItem(item_title, 'test_sample.mp4').then((id) => {
      createdItems.push(id);
      cy.get('[data-testid="media-object-publish-btn"]')
        .contains('Publish')
        .click();
      cy.get('[data-testid="alert"]').contains(
        'Media object successfully published.'
      );
      cy.wait(5000);
      cy.get('[data-testid="media-object-unpublish-btn"]').contains(
        'Unpublish'
      );
    });
    //Now navigate to unit page and list collections
    unitPage.navigateToUnit(unit_title);
    cy.get('[data-testid="unit-list-collections-btn"]')
      .should('be.visible')
      .click();
    //collection card check
    cy.get('[data-testid="collection-card-body"]')
      .find('a')
      .contains(collection_title)
      .click();
    //validate the collection has item card created above
    cy.get('[data-testid="collection-card-body"]')
      .find('a')
      .contains(item_title);
  });

  it('Assign Staff Roles: Verify the user is able to add an user as an unit administrator.', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);
    //checking the default admin user is present
    cy.get('[data-testid="collection-access-label-unit_admin"]').contains(
      admin
    );
    //add new unit admin
    cy.get('[data-testid="add_unit_admin-user-input"]')
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
    homePage.logout();
    cy.login('unit_admin');
    unitPage.navigateToUnit(unit_title);
    cy.get('[data-testid="unit-unit-details"]')
      .contains(unit_title)
      .should('be.visible');
    //validate that the collection has inherited the new unit admin as collection manager
    collectionPage.navigateToCollection(collection_title);
    cy.get('[data-testid="collection-access-label-manager"]')
      .should('be.visible')
      .and('contain.text', unit_admin)
      .and(
        'contain.text',
        'This role is inherited and cannot be removed.'
      );
    // should we validate the item access
  });

  it('Assign Staff Roles: Verify removing user from unit admin field', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);
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
    cy.login('unit_admin');
    //validate unit admin cannot navigate to collection
    cy.get('body').then(($body) => {
      if ($body.find('#manageDropdown').length) {
	navigateToManageContent();
	collectionPage.verifyCollectionNotAccessible(collection_title);
      }
    });
  });

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
    homePage.logout();
    cy.login('unit_manager');
    unitPage.navigateToUnit(unit_title);
    //title visible to manager
    cy.get('[data-testid="unit-unit-details"]')
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
    //validate that the collection has inherited the new manager as collection manager
    collectionPage.navigateToCollection(collection_title);
    cy.get('[data-testid="collection-access-label-manager"]')
      .should('be.visible')
      .and('contain.text', unit_manager)
      .and(
        'contain.text',
        'This role is inherited and cannot be removed.'
      );
  });

  it('Assign Staff Roles: Verify removing user from manager field', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);
    //add one manager as it won't allow to remove the manager role if it's the only manager present
    cy.get('[data-testid="add_manager-user-input"]')
      .type(manager)
      .should('have.value', manager);
    cy.get("[data-testid='add_manager-popup']")
      .children()
      .filter((_, el) => el.textContent.trim() === manager)
      .first()
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
    cy.get('body').then(($body) => {
      if ($body.find('#manageDropdown').length) {
	navigateToManageContent();
	unitPage.verifyUnitNotAccessible(unit_title);
	collectionPage.verifyCollectionNotAccessible(collection_title);
      }
    });
  });

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
    homePage.logout();
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
    //validate that the collection has inherited the new editor as collection editor
    collectionPage.navigateToCollection(collection_title);
    cy.get('[data-testid="collection-access-label-editor"]')
      .should('be.visible')
      .and('contain.text', user)
      .and(
        'contain.text',
        'This role is inherited and cannot be removed.'
      );
  });

  it('Assign Staff Roles: Verify removing user from editor field', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);
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
    cy.get('[data-testid="collection-access-label-editor"]').should(
      'not.exist'
    );
    //inherited in collection should be removed as well - assumed that user does not have any other collection or unit
    cy.login('user');
    cy.contains('Manage').should('not.exist');
  });

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
    homePage.logout();
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
    //validate that the collection has inherited the new depositor as collection depositor
    collectionPage.navigateToCollection(collection_title);
    cy.get('[data-testid="collection-access-label-depositor"]')
      .should('be.visible')
      .and('contain.text', user)
      .and(
        'contain.text',
        'This role is inherited and cannot be removed.'
      );
  });

  it('Assign Staff Roles: Verify removing user from depositor field', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);
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
    cy.get('[data-testid="collection-access-label-depositor"]').should(
      'not.exist'
    );
    //inherited in collection should be removed as well
    cy.login('user');
    cy.contains('Manage').should('not.exist');
  });

  it('Assign Staff Roles: Verify that the only user in the Unit Admin field cannot be removed.', () => {
    cy.login('administrator');
    unitPage.navigateToUnit(unit_title);

    //unit admin may be removed in a previous test so only remove if present
    cy.get('body').then(($body) => {
      if ($body.find('[data-testid="collection-access-label-unit_admin"]').length > 1) {
	// Remove unit admin
	cy.get('[data-testid="collection-access-label-unit_admin"]')
	  .contains('label', unit_admin)
	  .should('be.visible');
	cy.get('[data-testid="collection-access-label-unit_admin"]')
	  .contains('label', unit_admin)
	  .closest('tr')
	  .find('[data-testid="collection-access-remove-unit_admin"]')
	  .click();
      }
    });

    //verify admin is only unit admin present
    cy.get('[data-testid="collection-access-label-unit_admin"]').should('have.length', 1);
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
  });
});
