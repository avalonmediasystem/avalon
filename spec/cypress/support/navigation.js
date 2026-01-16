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

// Manage Content
export function navigateToManageContent() {
  cy.contains('Manage').click();
  cy.get('a[href="/admin/collections"]')
    .contains('Manage Content')
    .should('be.visible')
    .click();
}

// Collection Unit Selection
export function selectCollectionUnit() {
  cy.get("[data-testid='admin_collection[unit_name]-user-input']").type(
    'Automation Unit'
  ); // data-testid came from _autocomplete_input.html.erb
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
