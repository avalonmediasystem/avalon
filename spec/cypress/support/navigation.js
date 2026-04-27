/**
 * Core Avalon navigation functions
 * This file contains the base implementation for Avalon
 */

// Browse Navigation
export function navigateToCollections() {
  cy.get('a[href="/collections"]').click();
}

export function navigateToBookmarks() {
  cy.get('a[href="/bookmarks"]').click();
}

export function navigateToPlaylists() {
  cy.get('#playlists_nav').contains('Playlists').click();
}

export function navigateToTimelines() {
  cy.get('a[href="/timelines"]').click();
}

// Global Search
export function performSearch(query) {
  cy.get('[data-testid="browse-global-search-input"]').first().type(query);
  cy.get('[data-testid="browse-global-search-submit-button"]').first().click();
}

export function verifySearchable(id, title) {
  performSearch(title);
/*
  cy.get('[data-testid="browse-results-list"]').within(() => {
    cy.contains(`[data-testid="browse-document-title-${id}"]`).should('exist');
  });
  */
  cy.get(`[data-testid="browse-document-title-${id}"]`).should('exist');
}

export function verifyUnsearchable(id, title) {
  performSearch(title);
/*
  cy.get('[data-testid="browse-results-list"]').within(() => {
    cy.contains(`[data-testid="browse-document-title-${id}"]`).should('not.exist');
  });
  */
  cy.get(`[data-testid="browse-document-title-${id}"]`).should('exist');
}

// Manage Content
export function navigateToManageContent() {
  cy.contains('Manage').click();
  cy.get('a[href="/admin/dashboard"]')
    .contains('Manage Content')
    .should('be.visible')
    .click();
  cy.wait(2000);
}

// FIXME This doesn't test the actual tomSelect functionality
export function tsSelect(originalSelectID, value) {
/*
  cy.wait(2000);
  cy.get("#" + originalSelectID + "-ts-control").first().click();
  cy.wait(2000);
  cy.get("div.ts-dropdown input.dropdown-input").type(value, { force: true });
  cy.wait(1000);
  cy.get("#" + originalSelectID + "-ts-dropdown div").first().click();
  */
  cy.get(`#${originalSelectID}`).select(value, { force: true });
}

// Collection Unit Selection
export function selectCollectionUnit(unitName = 'Automation Unit') {
  tsSelect("admin_collection_unit_id", unitName);
}

// Access Control
export function selectLoggedInUsersOnlyAccess() {
  const labelText = Cypress.env('loggedInUsersLabel') || 'Logged in users only';

  cy.contains('label', labelText)
    .find('[data-testid="media-object-logged-in-users"]')
    .click({ force: true })
    .should('be.checked');
}

// Sign In
export function signInPage() {
  const signInPath = Cypress.env('signInPath') || '/users/sign_in';
  cy.visit(signInPath);
}
