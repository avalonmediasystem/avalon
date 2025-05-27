import { navigateToManageContent } from '../support/navigation';
class CollectionPage {
  navigateToCollection(collection_title) {
    navigateToManageContent();
    cy.get("[data-testid='collection-name-table']")
      .contains(collection_title)
      .click();
    cy.url().should('include', '/admin/collections/');
  }

  createItem(item_title, videoName) {
    // Create Item button
    cy.intercept('GET', '/media_objects/new?collection_id=*').as(
      'getManageFile'
    );
    cy.get("[data-testid='collection-create-item-btn']").click();
    cy.wait('@getManageFile').its('response.statusCode').should('eq', 302);

    // File upload
    cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect');
    cy.get("[data-testid='media-object-edit-select-file-btn']")
      .click()
      .selectFile(`spec/cypress/fixtures/${videoName}`);
    cy.get("[data-testid='media-object-edit-upload-btn']").click();
    cy.wait('@fileuploadredirect').its('response.statusCode').should('eq', 200);

    cy.get("[data-testid='media-object-edit-associated-files-block']").should(
      'contain',
      videoName
    );

    // Resource description
    cy.intercept('GET', '**/edit?step=resource-description').as(
      'resourcedescription'
    );
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@resourcedescription')
      .its('response.statusCode')
      .should('eq', 200);

    cy.get('[data-testid="resource-description-title"]').type(item_title);
    const publicationYear = String(
      Math.floor(Math.random() * (2020 - 1900 + 1)) + 1900
    );
    cy.get('[data-testid="resource-description-date-issued"]').type(
      publicationYear
    );

    // Structure page
    cy.intercept('GET', '**/edit?step=structure').as('structurepage');
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@structurepage').its('response.statusCode').should('eq', 200);

    // Access control page
    cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@accesspage').its('response.statusCode').should('eq', 200);

    // Complete creation
    cy.get('[data-testid="media-object-continue-btn"]').click();

    // Verify the item details
    cy.get('[data-testid="media-object-title"]').should(
      'contain.text',
      item_title
    );
    cy.get('[data-testid="metadata-display"]').within(() => {
      cy.get('dt')
        .contains('Publication date')
        .next('dd')
        .should('have.text', publicationYear);
    });

    // Return item_id
    return cy.url().then((url) => url.split('/').pop());
  }
}

export default CollectionPage;
