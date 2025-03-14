/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

context('Browse', () => {
	const homePage = new HomePage();

	it('should use the base URL', () => {
		cy.visit('/'); // This will navigate to CYPRESS_BASE_URL
		cy.screenshot()
	  });

  // checks navigation to Browse
  it('.browse_navigation()', () => {
		cy.login('administrator')
		cy.visit('/')
		homePage.getBrowseNavButton().click()
  })

  it('Verify searching for an item by keyword - @T9c1158fb', () => {
	cy.visit('/')
	homePage.getBrowseNavButton().click()
	//create a dynamic item here and use a portion of it as a search keyword
	const media_object_title = Cypress.env('MEDIA_OBJECT_TITLE')
	cy.get("input.global-search-input[placeholder='Search this site']").first().type(media_object_title).should('have.value', media_object_title) // Only yield inputs within form
	cy.get('button.global-search-submit').first().click()
	cy.contains('a', media_object_title)
	.should('exist')
	.and('be.visible');
})

it('Verify browsing items by a format - @Tb477685f', () => {
	cy.visit('/')
	homePage.getBrowseNavButton().click()
	cy.contains('button', 'Format').click()
	cy.contains('a', 'Moving Image').click()
	cy.get('.constraint-value').within(() => {
		cy.get('.filter-value[title="Moving Image"]')
		  .should('contain.text', 'Moving Image')
		  .and('be.visible');
	  });
	  //can assert the filtered items here
})


});


