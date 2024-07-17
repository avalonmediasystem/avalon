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

context('Item', () => {
	  //Create dynamic items here
	  const media_object_id = Cypress.env('MEDIA_OBJECT_ID_2')
	  const media_object_title = Cypress.env('MEDIA_OBJECT_TITLE_2')

  Cypress.on('uncaught:exception', (err, runnable) => {
	// Prevents Cypress from failing the test due to uncaught exceptions in the application code  - TypeError: Cannot read properties of undefined (reading 'scrollDown')
	if (err.message.includes('Cannot read properties of undefined (reading \'success\')')) {
	  return false;
	}
  });

  it('Verify setting Item access to “Collections staff only” for a published item - @T13b097f8', () => {
	cy.login('administrator')
	cy.visit('/')
	// The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
	cy.visit('/media_objects/' + media_object_id)
	cy.get('#administrative_options').find('a.btn').contains('Edit').click();
	cy.get('li.nav-item.nav-success')
  .contains('a.nav-link', 'Access Control')
  .click();
	cy.get('.item-access').within(() => {
		cy.contains('label', 'Collection staff only')
		.find('input[type="radio"]').click().should('be.checked');
		  });
	cy.get('input[type="submit"][name="save"]').click();

	//Login as a user who is not a staff to collection to validate the result
});

it('Verify setting Item access to “Logged in users only” for a published item - @T0cc6ee02', () => {
	cy.login('administrator')
	cy.visit('/')
	// The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
	cy.visit('/media_objects/' + media_object_id)
	cy.get('#administrative_options').find('a.btn').contains('Edit').click();
	cy.get('li.nav-item.nav-success')
  .contains('a.nav-link', 'Access Control')
  .click();
	cy.get('.item-access').within(() => {
		cy.contains('label', 'Logged in users only')
		.find('input[type="radio"]').click().should('be.checked');
		  });
	cy.get('input[type="submit"][name="save"]').click();

	//Login as a user who is not a staff to collection to validate the result
});

it('Verify setting Item access to “Available to general public” for a published item - @T593dc580', () => {
	cy.login('administrator')
	cy.visit('/')
	// The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
	cy.visit('/media_objects/' + media_object_id)
	cy.get('#administrative_options').find('a.btn').contains('Edit').click();
	cy.get('li.nav-item.nav-success')
  .contains('a.nav-link', 'Access Control')
  .click();
	cy.get('.item-access').within(() => {
		cy.contains('label', 'Available to the general public')
		.find('input[type="radio"]').click().should('be.checked');
		  });
	cy.get('input[type="submit"][name="save"]').click();

	//Login as a user who is not a staff to collection to validate the result
});

it('Verify setting Special access for an Avalon user - published item - @Ta15294e5', () => {
	cy.login('administrator')
	cy.visit('/')
	// The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
	cy.visit('/media_objects/' + media_object_id)
	cy.get('#administrative_options').find('a.btn').contains('Edit').click();
	cy.get('li.nav-item.nav-success')
  .contains('a.nav-link', 'Access Control')
  .click();
	cy.get('.item-access').within(() => {
		cy.contains('label', 'Available to the general public')
		.find('input[type="radio"]').click().should('be.checked');
		  });
	cy.get('input[type="submit"][name="save"]').click();

	//Login as a user who is not a staff to collection to validate the result
});




 

})
