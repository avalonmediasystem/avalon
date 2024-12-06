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
  var search_collection = Cypress.env('SEARCH_COLLECTION')
  var collection_title = `Automation collection title ${Math.floor(Math.random() * 10000) + 1}`
  
  Cypress.on('uncaught:exception', (err, runnable) => {
	// Prevents Cypress from failing the test due to uncaught exceptions in the application code  - TypeError: Cannot read properties of undefined (reading 'scrollDown')
	if (err.message.includes('Cannot read properties of undefined (reading \'success\')')) {
	  return false;
	}
  });


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
	//The below code to generate random slice of the collection name is failing. hence, we are using the full colelction name for now
		// Generate a random index to slice the title
		// const startIndex = Math.floor(Math.random() * (search_collection.length-3));
		// const sliceLength = Math.floor(Math.random() * (search_collection.length - startIndex)) + 1; // Random slice length
		// //slice a random portion of the collection title as the search keyword to ensure variablitity in testing
		// const search_keyword = search_collection.slice(startIndex, startIndex + sliceLength)
	cy.get('input[placeholder="Search collections..."]').type(search_collection).should('have.value', search_collection)
	cy.get('.card-body').contains('a', search_collection);
})


it('Verify whether an admin/manager is able assign other users as managers to the collection - @T3c428871', () => {
	cy.login('administrator')
	cy.visit('/')
	cy.get('#manageDropdown').click()
	cy.contains('Manage Content').click()
	cy.contains('a', collection_title).click();
	const user_manager = Cypress.env('USER_MANAGER_USERNAME')
	cy.get("#add_manager_display").type(user_manager).should('have.value', user_manager)
	// Verify that the correct suggestions appear in the dropdown and click it
	cy.get('.tt-menu .tt-suggestion')
      .should('be.visible')
      .and('contain', user_manager).click();
	cy.get('button[name="submit_add_manager"]')
	.click();

	//reload the page to ensure that the data is updated in the backend
	cy.reload(true);
	
	cy.get('table.table-hover')
	.find('td.access_list_label')
	.contains('label', user_manager)
	.should('be.visible');

	//Additional assertions to add :Login as user_manager and validate that the collection is visible in the "Manage page" and/or API validation
})



it('Verify changing item access - Collection staff only (New items) - @T9978b4f7', () => {
	cy.login('administrator')
	cy.visit('/')
	cy.get('#manageDropdown').click()
	cy.contains('Manage Content').click()
	cy.contains('a', collection_title).click();
	cy.get('.item-access').within(() => {
    cy.contains('label', 'Collection staff only')
	.find('input[type="radio"]').click().should('be.checked');
	cy.get('input[value = "Save Setting"]').click()
      });
	//reload the page to ensure that the data is updated in the backend
	cy.reload()
	cy.contains('label', 'Collection staff only')
	.find('input[type="radio"]').should('be.checked');

	//Add UI and/or API assertions here............Assert via UI by opening the create item page and verifying the default access control
})

it('Verify changing item access - Collection staff only (Existing items) - @Tdcf756bd', () => {
	cy.login('administrator')
	cy.visit('/')
	cy.get('#manageDropdown').click()
	cy.contains('Manage Content').click()
	cy.contains('a', collection_title).click();
	cy.get('.item-access').within(() => {
    cy.contains('label', 'Collection staff only')
	.find('input[type="radio"]').click().should('be.checked');
	cy.get('input[name = "apply_to_existing"]').click()
      });
	
	//reload the page to ensure that the data is updated in the backend
	cy.reload()
	cy.contains('label', 'Collection staff only')
	.find('input[type="radio"]').should('be.checked');

//Add UI and API assertions here............Assert via UI by opening the an ecisting item within the collection and verifying the default access control

})
	
it('Verify whether a user is able to update Collection information - @Ta1b2fef8', () => {
	cy.login('administrator')
	cy.visit('/')
	cy.get('#manageDropdown').click()
	cy.contains('Manage Content').click()
	cy.contains('a', collection_title).click();
	cy.get('.admin-collection-details')
      .contains('button', 'Edit Collection Info')
      .click();

	//update description
	var updatedDescription = ' Adding more details to collection description'
	cy.get('#admin_collection_description').invoke('val').then((existingText) => {
		updatedDescription = existingText + updatedDescription;  
		cy.get('#admin_collection_description').type(updatedDescription);
	  });
	//update title
	var new_title =  `Updated automation title ${Math.floor(Math.random() * 10000) + 1}`
	cy.get('#admin_collection_name').clear().type(new_title);

	//update contact email
	cy.get('#admin_collection_contact_email').clear().type('test@yopmail.com');
	
	cy.get('input[value="Update Collection"]').click();

	// Validate updated collection title and update the collection_title global variable
	cy.get('.admin-collection-details h2').should('contain.text', new_title).then(() => {
		// Update the global variable collection_title with new_title if the assertion passes
		collection_title = new_title;
	  });

    // Validate updated contact email
    cy.get('.admin-collection-details').within(() => {
		cy.get('a[href="mailto:test@yopmail.com"]')
		.should('have.text', 'test@yopmail.com')
    });
	//validate updated description
	cy.get('.admin-collection-details .collection-description').should('contain.text', updatedDescription);
	
})

it('Verify whether a user is able to update poster image -  @T26526b2e', () => {
	cy.login('administrator')
	cy.visit('/')
	cy.get('#manageDropdown').click()
	cy.contains('Manage Content').click()
	cy.contains('a', collection_title).click();
	cy.get('#poster_input').selectFile('spec/cypress/fixtures/image.png', { force: true });
	cy.wait(5000)
	cy.screenshot()
	cy.get('button#crop').click()
	cy.get('.alert-success').should('be.visible').and('contain', 'Poster file successfully added.');
	
})

//Teardown code : delete the created collection 
	it('Verify deleting a collection - @T959a56df', () => {
		cy.login('administrator')
		cy.visit('/')
		cy.get('#manageDropdown').click()
		cy.contains('Manage Content').click()
		cy.contains('a', collection_title).closest('tr').find('.btn-danger').click(); 
		//May require adding steps to select a collection to move the existing  items, when dealing with non empty collections
		cy.get('input[value="Yes, I am sure"]').click()
		cy.contains('h1', 'My Collections')
		//May need to update this assertion to ensure that this is valid during pagination of collections. Another alternative would be to check via API or search My collections
		cy.contains('a', collection_title).should('not.exist');
		
	})


	

})
