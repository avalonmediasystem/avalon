import { navigateToManageContent } from '../support/navigation.js';

class UnitPage {
  //navigate to unit page
  navigateToUnit(collection_title) {
    navigateToManageContent();
    cy.get("[data-testid='collection-name-table']")
      .contains(collection_title)
      .click();
    cy.url().should('include', '/admin/unit/');
  }
  // Unit creation - used by collection specs
  createUnit(unitData, options = {}) {
    const defaults = {
      description: 'Automation Unit Description',
      contactEmail: 'administrator@example.com',
      websiteUrl: 'http://www.example.com',
      websiteLabel: 'Website label',
      navigate: true,
      managerUsername: Cypress.env('USERS_MANAGER_USERNAME') || 'manager',
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

    cy.get('[data-testid="alert"]').contains('unit was successfully created.');
    cy.get('[data-testid="unit-unit-details"]').contains(config.title);
    cy.get('[data-testid="unit-description"]').contains(config.description);
    cy.get('[data-testid="unit-contact-email"]').contains(config.contactEmail);

    //add manager
    cy.get("[data-testid='add_manager-user-input']")
      .type(config.managerUsername)
      .should('have.value', config.managerUsername);

    cy.get("[data-testid='add_manager-popup']")
      .should('be.visible')
      .and('contain', config.managerUsername)
      .click();

    cy.get("[data-testid='submit-add-manager']").click();

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

    cy.get('body').then(($body) => {
      if (
        $body.find(`[data-testid='unit-name-table']:contains("${unitName}")`)
          .length > 0
      ) {
        cy.get("[data-testid='unit-name-table']")
          .contains(unitName)
          .closest('tr')
          .find("[data-testid='unit-delete-unit-btn']")
          .click();

        cy.intercept('POST', '/admin/units/*').as('deleteUnit');

        if (config.reassignTo) {
          cy.get('#target_unit_id').select(config.reassignTo);
        }

        cy.get("[data-testid='unit-delete-confirm-btn']").click();

        cy.wait('@deleteUnit').then((interception) => {
          expect(interception.response.statusCode).to.eq(302);
          expect(interception.response.headers.location).to.include(
            '/admin/units'
          );
        });

        // Refresh and verify deletion
        navigateToManageContent();
        cy.get("[data-testid='unit-name-table']")
          .contains(unitName)
          .should('not.exist');
      }
    });
  }
}

export default new UnitPage();
