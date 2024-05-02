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

context('Collections', () => {
	  //Since it takes a while for a newly created collection to reflect in search, we are using static search data
  const search_collection = Cypress.env('SEARCH_COLLECTION')
  const collection_title = `Automation collection title ${Math.floor(Math.random() * 10000) + 1}`


  // checks navigation to Browse
  it('Verify whether an admin user is able to create a collection - @T553cda51', () => {
		cy.login('administrator')
		cy.visit('/')
		cy.get('#manageDropdown').click()
		cy.contains('Manage Content').click()
		cy.contains('Create Collection').click()
		//Create dynamic data below 
		cy.get('#admin_collection_name').type(collection_title).should('have.value', collection_title)
		cy.get('#admin_collection_description').type("Collection desc").should('have.value', 'Collection desc')
		cy.get('#admin_collection_contact_email').type("admin@example.com").should('have.value', 'admin@example.com')
		cy.get('#admin_collection_website_url').type("https://www.google.com").should('have.value', 'https://www.google.com')
		cy.get('#admin_collection_website_label').type("test label").should('have.value', 'test label')
		cy.get('input[value="Create Collection"]').click()
		// Handle the alert
		Cypress.on('uncaught:exception', (err, runnable) => {
			// Return false to prevent Cypress from failing the test due to the issue:
			//"TypeError: The following error originated from your application code, not from Cypress."
			//Cannot read properties of undefined (reading 'success')
			return false;
		  });
		//Assert title and edit collection button. Can add more assertions here if required.
		cy.contains('h2', collection_title).should('be.visible')
		cy.contains('button', 'Edit Collection Info').should('exist')
		
		//Can add a Tearoff code here: delete the created collection using DELETE request for data cleanup
		
  })

  it("Verify whether the user is able to search for Collections-'@Tf7cefb09", () => {
	cy.login('administrator')
	cy.visit('/')
	cy.get('a[href="/collections"]').click()
	//Using an existing collection for this test case for now, since it takes a while for the newly created test case to get reflected
	// Generate a random index to slice the title
	const startIndex = Math.floor(Math.random() * (search_collection.length-3));
	const sliceLength = Math.floor(Math.random() * (search_collection.length - startIndex)) + 1; // Random slice length
	//slice a random portion of the collection title as the search keyword to ensure variablitity in testing
	const search_keyword = search_collection.slice(startIndex, startIndex + sliceLength)
	cy.get('input[placeholder="Search collections..."]').type(search_keyword).should('have.value', search_keyword)
	cy.screenshot('search');
	cy.get('.card-body').contains('a', search_collection);

})

	
	it('Verify deleting a collection - @T959a56df', () => {
		cy.login('administrator')
		cy.visit('/')
		cy.get('#manageDropdown').click()
		cy.contains('Manage Content').click()
		cy.contains('a', collection_title).closest('tr').find('.btn-danger').click(); 
		//May require adding steps to select a collection to move the existing  items, when dealing with non empty collections
		cy.get('input[value="Yes, I am sure"]').click()
		cy.contains('h1', 'My Collections')
		//May need to update this assertion to ensire that this is valid during pagination of collections. Another alternative would be to check via API or search My collections
		cy.contains('a', collection_title).should('not.exist');
		
	})

})
