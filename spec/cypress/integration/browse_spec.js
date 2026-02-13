/*
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
 */

import HomePage from '../pageObjects/homePage';
import { performSearch } from '../support/navigation';

context('Browse', () => {
  const homePage = new HomePage();

  it('should use the base URL', { tags: '@critical' }, () => {
    cy.visit('/'); // This will navigate to CYPRESS_BASE_URL
    cy.screenshot();
  });

  // checks navigation to Browse
  it('.browse_navigation()', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.visit('/');
    homePage.getBrowseNavButton().click();
  });

  it(
    'Verify searching for an item by keyword - @T9c1158fb',
    { tags: '@critical' },
    () => {
      cy.visit('/');
      homePage.getBrowseNavButton().click();
      //create a dynamic item here and use a portion of it as a search keyword
      //const media_object_title = Cypress.env('MEDIA_OBJECT_TITLE'); //need to take a look at
      const media_object = `Lunchroom Manners`;
      performSearch('Lunchroom Manners');
      cy.contains('a', media_object).should('exist').and('be.visible');
    }
  );

  it(
    'Verify browsing items by a format - @Tb477685f',
    { tags: '@critical' },
    () => {
      cy.login('administrator');
      cy.visit('/');

      homePage.getBrowseNavButton().click();
      cy.contains('button', 'Format').click();
      cy.contains('a', 'Moving Image').click();
      cy.get('.constraint-value').within(() => {
        cy.get('.filter-value[title="Moving Image"]')
          .should('contain.text', 'Moving Image')
          .and('be.visible');
      });
      //can assert the filtered items here
    }
  );

it(
  'displays items correctly per page and items render after scroll',
  { tags: '@critical' },
  () => {
    cy.login('administrator');
    cy.visit('/');
    homePage.getBrowseNavButton().click();

    // Wait for results list to exist
    cy.get('[data-testid="browse-results-list"]').should('exist');

    // Read pagination summary text and assert count accordingly
    cy.get('.page-entries')
      .should('exist')
      .invoke('text')
      .then((rawText) => {
        const text = rawText.replace(/\s+/g, ' ').trim();

        // Case 1:local sometimes shows "1 entry found"
        if (/entry found/i.test(text)) {
          cy.get('[data-testid="browse-results-list"]')
            .find('article')
            .its('length')
            .should('be.gte', 1);
          return;
        }

        //Case B: dev shows " 1 - 10 of 345 " extracting thatinfo
        const matches = text.match(/(\d+)\s*-\s*(\d+)\s*of\s*(\d+)/);
        expect(matches, 'Pagination summary format').to.not.be.null;

        const start = parseInt(matches[1], 10);
        const end = parseInt(matches[2], 10);

        const expectedCount = end - start + 1;

        cy.get('[data-testid="browse-results-list"]')
          .find('article')
          .should('have.length', expectedCount);
      });

    // Scroll and ensure list is still populated
    cy.scrollTo('bottom');

    cy.get('[data-testid="browse-results-list"]')
      .find('article')
      .its('length')
      .should('be.gte', 1);
  }
);


  it(
    'Selects the "Sort by" dropdown and chooses "Date"',
    { tags: '@high' },
    () => {
      cy.login('administrator');
      homePage.getBrowseNavButton().click();
      // Click the Sort by dropdown toggle button
      cy.get('#sort-dropdown button').should('be.visible').click();

      // Make sure the dropdown menu appears
      cy.get('#sort-dropdown .dropdown-menu').should('be.visible');

      // Click the "Date" option
      cy.get('#sort-dropdown .dropdown-menu').contains('Date').click();

      // Verify the URL now includes the sort parameter for Date
      cy.url().should('include', 'sort=date_issued_ssi');

      // Get all date elements
      cy.get('[data-testid="browse-value-date_issued_ssi"]').then(($dates) => {
        // Extract date text, convert to number, store in array
        const dateNumbers = [...$dates].map((el) =>
          parseInt(el.innerText.trim())
        );

        // Make a sorted copy to compare
        const sortedDates = [...dateNumbers].sort((a, b) => b - a);

        // Assert the dates are sorted DESC
        expect(dateNumbers).to.deep.equal(sortedDates);
      });
    }
  );
});
