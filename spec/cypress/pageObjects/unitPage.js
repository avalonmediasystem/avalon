import { navigateToManageContent, tsSelect } from '../support/navigation.js';

class UnitPage {
  //navigate to unit page
  navigateToUnit(unit_title) {
    navigateToManageContent();
    cy.get('[data-testid="unit-table-search-field"]')
      .clear()
      .type(unit_title);
    cy.get("[data-testid='unit-name-table']").contains(unit_title).click();
    cy.url().should('include', '/admin/units/');
  }
  // Unit creation - used by collection specs
  createUnit(unitData, options = {}) {
    const defaults = {
      description: 'Automation Unit Description',
      contactEmail: 'administrator@example.com',
      websiteUrl: 'http://www.example.com',
      websiteLabel: 'Website label',
      navigate: true,
      unitManagerUsername: Cypress.env('USERS_UNITMANAGER_EMAIL'),
      unitAdminUsername: Cypress.env('USERS_UNITADMIN_EMAIL'),
    };

    const config = { ...defaults, ...unitData, ...options };

    if (config.navigate) {
      navigateToManageContent();
    }

    cy.get('[data-testid="unit-create-unit-button"]').click();

    cy.get('[data-testid="unit-name"]')
      .type(config.title)
      .should('have.value', config.title);
    cy.get('[data-testid="unit-description"]')
      .type(config.description)
      .should('have.value', config.description);
    cy.get('[data-testid="unit-contact-email"]')
      .type(config.contactEmail)
      .should('have.value', config.contactEmail);
    cy.get('[data-testid="unit-website-url"]')
      .type(config.websiteUrl)
      .should('have.value', config.websiteUrl);
    cy.get('[data-testid="unit-website-label"]')
      .type(config.websiteLabel)
      .should('have.value', config.websiteLabel);

    cy.get('[data-testid="unit-new-unit-btn"]').click();

    cy.get('[data-testid="alert"]').contains('Unit was successfully created.');
    cy.get('[data-testid="unit-unit-details"]').contains(config.title);
    cy.get('[data-testid="unit-description"]').contains(config.description);
    cy.get('[data-testid="unit-contact-email"]').contains(config.contactEmail);
    cy.get('[data-testid="unit-website-url"]')
      .should('be.visible')
      .and('have.attr', 'href', config.websiteUrl)
      .and('contain.text', config.websiteLabel);

    //add unit admin
    cy.get("[data-testid='add_unit_admin-user-input']")
      .type(config.unitAdminUsername)
      .should('have.value', config.unitAdminUsername);

    cy.get("[data-testid='add_unit_admin-popup']")
      .should('be.visible')
      .and('contain', config.unitAdminUsername)
      .click();

    cy.get("[data-testid='submit-add-unit_admin']").click();

    //add unit manager
    cy.get("[data-testid='add_manager-user-input']")
      .type(config.unitManagerUsername)
      .should('have.value', config.unitManagerUsername);

    cy.get("[data-testid='add_manager-popup']")
      .should('be.visible')
      .and('contain', config.unitManagerUsername)
      .click();

    cy.get("[data-testid='submit-add-manager']").click();

    return cy.wrap(config.title);
  }

  createCollectionInUnit(unit_title, collectionData, options = {}) {
    const defaults = {
      description: 'Automation Unit Description',
      contactEmail: 'administrator@example.com',
      websiteUrl: 'http://www.example.com',
      websiteLabel: 'Website label',
      navigate: true,
    };

    const config = { ...defaults, ...collectionData, ...options };

    if (config.navigate) {
      this.navigateToUnit(unit_title);
    }

    cy.get('[data-testid="unit-create-collection-btn"]')
      .should('be.visible')
      .click();

    // fill out collection form - name, unit and description
    cy.get('[data-testid="collection-name"]')
      .type(config.title)
      .should('have.value', config.title);
    cy.get('[data-testid="collection-description"]')
      .type(config.description)
      .should('have.value', config.description);
    cy.get('[data-testid="collection-contact-email"]')
      .type(config.contactEmail)
      .should('have.value', config.contactEmail);
    cy.get('[data-testid="collection-website-url"]')
      .type(config.websiteUrl)
      .should('have.value', config.websiteUrl);
    cy.get('[data-testid="collection-website-label"]')
      .type(config.websiteLabel)
      .should('have.value', config.websiteLabel);

    // Validate unit
    cy.get('[data-testid="collection-unit"] option').should('have.text', unit_title);

    cy.get('[data-testid="collection-new-collection-btn"]').click();

    // Validate collection creation
    cy.get('[data-testid="alert"]').contains('Collection was successfully created.');
    cy.get('[data-testid="collection-collection-details"]').contains(config.title);
    cy.get('[data-testid="collection-unit"]').contains(unit_title);
    cy.get('[data-testid="collection-description"]').contains(config.description);
    cy.get('[data-testid="collection-contact-email"]').contains(config.contactEmail);
    cy.get('[data-testid="collection-website-url"]')
      .should('be.visible')
      .and('have.attr', 'href', config.websiteUrl)
      .and('contain.text', config.websiteLabel);

    return cy.wrap(config.title);
  }

  // Cleanup method for unit created
  deleteUnitByName(unitName, options = {}) {
    const defaults = {
      navigate: true,
      reassignTo: null,
    };

    const config = { ...defaults, ...options };

    if (config.navigate) {
      navigateToManageContent();
    }

    cy.get('[data-testid="unit-table-search-field"]')
      .clear()
      .type(unitName);
    cy.get("[data-testid='unit-name-table']")
      .contains(unitName)
      .closest('tr')
      .find("[data-testid='unit-delete-unit-btn']")
      .click();

    cy.intercept('POST', '/admin/units/*').as('deleteUnit');

    if (config.reassignTo) {
      tsSelect('target_unit_id', config.reassignTo);
    }

    cy.get("[data-testid='unit-delete-confirm-btn']").click();

    cy.wait('@deleteUnit').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include(
	'/admin/dashboard'
      );
    });

    // Refresh and verify deletion
    navigateToManageContent();
    cy.get('[data-testid="unit-table-search-field"]')
      .clear()
      .type(unitName);
    cy.get("[data-testid='unit-table-body']").within(() => {
       cy.contains(
	'td',
	'No matching records found',
       ).should('be.visible');
    });
  }

  verifyUnitNotAccessible(unit_title) {
    cy.get('body').then(($body) => {
      if ($body.find('[data-testid="unit-table-search-field"]').length) {
	cy.get('[data-testid="unit-table-search-field"]')
	  .clear()
	  .type(unit_title);
	cy.wait(1000);
	cy.get('[data-testid="unit-table-body"] tr td').should('contain', "No matching records found");
      } else {
	cy.contains('h2', "You don't have any units yet").should('be.visible');
	cy.contains('p', "You'll need to be assigned to one").should('be.visible');
      }
    });
  }
}

export default UnitPage;
