// Checking the baseurl -- mco or avalon
function getPlatform() {
  const baseUrl = Cypress.config('baseUrl') || '';
  if (baseUrl.includes('avalon') || baseUrl.includes('localhost'))
    return 'avalon';
  if (baseUrl.includes('mco')) return 'mco';
  throw new Error(`Unknown platform from baseUrl: ${baseUrl}`);
}
// Browse

// Collection
export function navigateToCollections() {
  const platform = getPlatform();

  if (platform === 'mco') {
    cy.get('[data-testid="collections-link"]').click();
  } else if (platform === 'avalon') {
    cy.get('a[href="/collections"]').click();
  }
}
// Seelected item - Bookmark
export function navigateToBookmarks() {
  const platform = getPlatform();

  if (platform === 'mco') {
    cy.get('[data-testid="selected-items-link"]').click();
  } else if (platform === 'avalon') {
    cy.get('a[href="/bookmarks"]').click();
  }
}

// Playlist
export function navigateToPlaylists() {
  const platform = getPlatform();

  if (platform === 'mco') {
    cy.get('[data-testid="playlist-link"]').click();
  } else if (platform === 'avalon') {
    cy.get('a[href="/playlists"]').click();
  }
}

// Timeline
export function navigateToTimelines() {
  const platform = getPlatform();

  if (platform === 'mco') {
    cy.get('[data-testid="timelines-link"]').click();
  } else if (platform === 'avalon') {
    cy.get('a[href="/timelines"]').click();
  }
}

// Global Search
export function performSearch(query) {
  const platform = getPlatform();

  if (platform === 'avalon') {
    cy.get('[data-testid="browse-global-search-input"]').first().type(query);
    cy.get('[data-testid="browse-global-search-submit-button"]')
      .first()
      .click();
  } else if (platform === 'mco') {
    // Clicking to reveal the search field
    cy.get('[data-testid="primary-nav-search"]').click();

    // Typing into the search input
    cy.get('[data-testid="primary-nav-search-input"]').type(query);

    // Clicking on the search button
    cy.get('[data-testid="primary-nav-search-button"]').click();
  }
}

// Manage - Manage Content

export function navigateToManageContent() {
  const platform = getPlatform();

  if (platform === 'avalon') {
    cy.contains('Manage').click();
    cy.get('a[href="/admin/collections"]')
      .contains('Manage Content')
      .should('be.visible')
      .click();
  } else if (platform === 'mco') {
    // Click on dropdown icon
    cy.get('[data-rvt-dropdown-toggle="secondary-nav-2"]').click();

    // Click on Manage content
    cy.get('a[data-testid="manage-content-link"]').should('be.visible').click();
  }
}
// Selecting unit while creating collection
export function selectCollectionUnit() {
  const platform = getPlatform();

  const unit =
    platform === 'avalon' ? 'Default Unit' : 'Indiana University Libraries';

  cy.get("[data-testid='collection-unit']")
    .select(unit)
    .should('have.value', unit);
}

// Access control of an item - Logged in Users
export function selectLoggedInUsersOnlyAccess() {
  const platform = getPlatform();

  const labelText =
    platform === 'mco'
      ? 'Logged-in IU Users Only (Students, Faculty, Staff & Affiliates)'
      : 'Logged in users only';

  cy.contains('label', labelText)
    .find('[data-testid="media-object-logged-in-users"]')
    .click({ force: true })
    .should('be.checked');
}

// Sign in page
export function signInPage() {
  const platform = getPlatform();

  const path =
    platform === 'mco'
      ? '/users/sign_in?admin=true&email=true'
      : '/users/sign_in';

  cy.visit(path);
}
