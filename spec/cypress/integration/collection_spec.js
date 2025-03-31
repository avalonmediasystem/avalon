context('Collections Test', () => {
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
		cy.contains('Manage').click();
		cy.get('a[href="/admin/collections"]').contains('Manage Content').should('be.visible').click();
		cy.get("[data-testid='collection-create-collection-button']").contains('Create Collection').click()
        // Intercept the POST request for creating a collection
        cy.intercept('POST', '/admin/collections').as('createCollection');
		//Create dynamic data below 
		cy.get("[data-testid='collection-name']").type(collection_title).should('have.value', collection_title)
		cy.get("[data-testid='collection-unit']").select("Default Unit").should('have.value', 'Default Unit') //added unit as it is mandatory
		cy.get("[data-testid='collection-description']").type("Collection desc").should('have.value', 'Collection desc')
		cy.get("[data-testid='collection-contact-email']").type("admin@example.com").should('have.value', 'admin@example.com')
		cy.get("[data-testid='collection-website-url']").type("https://www.google.com").should('have.value', 'https://www.google.com')
		cy.get("[data-testid='collection-website-label']").type("test label").should('have.value', 'test label')
		cy.get("[data-testid='collection-new-collection-btn']").click() //introduced id here as the text on button change would cause this fail 
		// Handle the alert
		Cypress.on('uncaught:exception', (err, runnable) => {

			return false;
		});

        // Wait for the intercepted request and validating the response. Intercepting the async behaviour
        cy.wait('@createCollection').then((interception) => {
            expect(interception.response.statusCode).to.eq(302);
            expect(interception.response.headers.location).to.include('/admin/collections/');
        });

		//Assert title and edit collection button. Can add more assertions here if required.
        cy.get("[data-testid='collection-collection-details']").contains(collection_title).should('be.visible')
		cy.get("[data-testid='collection-edit-collection-info']").should('exist')

		

	})

    it("Verify whether the user is able to search for Collections-'@Tf7cefb09", () => {
		cy.login('administrator')
		cy.visit('/')
		cy.get('a[href="/collections"]').contains(/Collections$/).should('be.visible').click();// added should be visible so when a page is loading it won't cause problems
		cy.get("[data-testid='collection-search-collection-input']").type(search_collection).should('have.value', search_collection)// if the placeholder text changes; hence introduce ids
		cy.get("[data-testid='collection-card-body']").contains('a', search_collection);
	})

    it('Verify whether an admin/manager is able assign other users as managers to the collection - @T3c428871', () => {
        cy.login('administrator')
        cy.visit('/')
        cy.contains('Manage').click();
		cy.get('a[href="/admin/collections"]').contains('Manage Content').should('be.visible').click();
        cy.get("[data-testid='collection-name-table']").contains(collection_title).click(); 
        cy.intercept('POST', '/admin/collections/*').as('updateCollectionManager');
        const user_manager = Cypress.env('USERS_MANAGER_USERNAME')
        cy.get('input[name="add_manager_display"]').type(user_manager).should('have.value', user_manager)
        // Verify that the correct suggestions appear in the dropdown and click it
        cy.get('.tt-menu .tt-suggestion') //cannot add id for this as this is configured by typeahead.js. they render the elements directs app/javascript/autocomplete.j
          .should('be.visible')
          .and('contain', user_manager).click();
        cy.get("[data-testid='submit-add-manager']")
        .click();

        cy.wait('@updateCollectionManager').then((interception) => {
            expect(interception.response.statusCode).to.eq(302);
            expect(interception.response.headers.location).to.include('/admin/collections/');
        });
    
        //reload the page to ensure that the data is updated in the backend
        //cy.reload(true);
        
        cy.get("[data-testid='collection-access-label-manager']")//introduced id here
        .should('exist')
        .contains('label', user_manager)
        .should('be.visible');
    
        //Additional assertions to add :Login as user_manager and validate that the collection is visible in the "Manage page" and/or API validation
    })

    it('Verify changing item access - Collection staff only (New items) - @T9978b4f7', () => {
        cy.login('administrator')
        cy.visit('/')
        cy.contains('Manage').click();
		cy.get('a[href="/admin/collections"]').contains('Manage Content').should('be.visible').click();
        cy.get("[data-testid='collection-name-table']").contains(collection_title).click(); 
        cy.intercept('POST', '/admin/collections/*').as('updateAccessControl');
        cy.get("[data-testid='collection-item-access']").within(() => { //added id here
        cy.contains('label', 'Collection staff only')
        .find("[data-testid='collection-checkbox-collection-staff']").click().should('be.checked');
        cy.get("[data-testid='collection-save-setting-btn']").click() //we can introduce an id here if the name were to change
          });
          //check if the status was 200 to make sure the setting was saved
        cy.wait('@updateAccessControl').then((interception) => {
            expect(interception.response.statusCode).to.eq(302);
            expect(interception.response.headers.location).to.include('/admin/collections/');
        });
        cy.contains('label', 'Collection staff only')
        .find("[data-testid='collection-checkbox-collection-staff']").should('be.checked');
    
        //Add UI and/or API assertions here............Assert via UI by opening the create item page and verifying the default access control
    })

    it('Verify changing item access - Collection staff only (Existing items) - @Tdcf756bd', () => {
        cy.login('administrator')
        cy.visit('/')
        cy.contains('Manage').click();
		cy.get('a[href="/admin/collections"]').contains('Manage Content').should('be.visible').click();
        cy.get("[data-testid='collection-name-table']").contains(collection_title).click(); 
        cy.intercept('POST', '/admin/collections/*').as('updateAccessControl');
        cy.get("[data-testid='collection-item-access']").within(() => {
            cy.contains('label', 'Collection staff only')
                .find("[data-testid='collection-checkbox-collection-staff']").click().should('be.checked');
            cy.get("[data-testid='collection-apply-to-existing-btn']").click()
        });
        cy.wait('@updateAccessControl').then((interception) => {
            expect(interception.response.statusCode).to.eq(302);
            expect(interception.response.headers.location).to.include('/admin/collections/');
        });       
        //reload the page to ensure that the data is updated in the backend
        //cy.reload()
        cy.contains('label', 'Collection staff only')
            .find("[data-testid='collection-checkbox-collection-staff']").should('be.checked');
    
    //Add UI and API assertions here............Assert via UI by opening the an ecisting item within the collection and verifying the default access control
    
    })

    it('Verify whether a user is able to update Collection information - @Ta1b2fef8', () => {
        cy.login('administrator')
        cy.visit('/')
        cy.contains('Manage').click();
		cy.get('a[href="/admin/collections"]').contains('Manage Content').should('be.visible').click();
        cy.get("[data-testid='collection-name-table']").contains(collection_title).click(); 
        cy.get("[data-testid='collection-edit-collection-info']")
            .should('exist')
            .and('contain.text', 'Edit Collection Info')
            .click(); //this will make sure that button is fully loaded before we click on it 

        cy.location('pathname').then((path) => {
            const collectionId = path.split('/').pop();  // Extracts the last part of the URL
            cy.log(`The collection ID is: ${collectionId}`);

            cy.intercept('POST', `/admin/collections/${collectionId}.json`).as('updateCollectionInfo');
            });
               
        //update contact email
        cy.get("[data-testid='collection-update-contact-email']").clear().type('test1@mail.com');
         //update title
        var new_title =  `Updated automation title ${Math.floor(Math.random() * 10000) + 1}`;
        cy.get("[data-testid='collection-update-name']input").clear().type(new_title);
            
                
       

        //update description
        var updatedDescription = ' Adding more details to collection description'
        cy.get("[data-testid='collection-update-description']").invoke('val').then((existingText) => {
            updatedDescription = existingText + updatedDescription;  
            cy.get("[data-testid='collection-update-description']").type(updatedDescription);
          });

        //click on update button
        cy.get("[data-testid='collection-update-collection-btn']").click();

        cy.wait('@updateCollectionInfo').then((interception) => {
            expect(interception.response.statusCode).to.eq(200);  // Ensure successful update
        });
    
        // Validate updated collection title and update the collection_title global variable
        //replaced classes with id: adminCollectionDetails and 
        cy.get("[data-testid='collection-collection-details']").should('contain.text', new_title).then(() => { 
            // Update the global variable collection_title with new_title if the assertion passes
            collection_title = new_title;
          });
    
        // Validate updated contact email and description
        cy.get("[data-testid='collection-collection-details']").within(() => {
            cy.get("[data-testid='collection-contact-email']")
                .should('have.text', 'test1@mail.com')
            cy.get("[data-testid='collection-description']").should('contain.text', updatedDescription);
        });
        
        
    })

    it('Verify whether a user is able to update poster image -  @T26526b2e', () => {
        cy.login('administrator')
        cy.visit('/')
        cy.contains('Manage').click();
		cy.get('a[href="/admin/collections"]').contains('Manage Content').should('be.visible').click();
        cy.get("[data-testid='collection-name-table']").contains(collection_title).click(); 
        cy.intercept('POST', '**/poster').as('updatePoster');
        cy.get("[data-testid='collection-poster-input']").selectFile('spec/cypress/fixtures/image.png', { force: true });
        cy.wait(5000)
        cy.screenshot()
        cy.get("[data-testid='collection-upload-poster']").click()
        //Added sync api check 
        cy.wait('@updatePoster').then((interception) => {
            expect(interception.response.statusCode).to.eq(302);
            expect(interception.response.headers.location).to.include('/admin/collections/');
        });
        //These test will only start after the api is validated
        cy.get("[data-testid='alert']").contains('Poster file successfully added.') 
            .should('be.visible')
            .and('be.visible');
        
    })

    it('Verify deleting a collection - @T959a56df', () => {
		cy.login('administrator')
		cy.visit('/')
        cy.contains('Manage').click();
		cy.get('a[href="/admin/collections"]').contains('Manage Content').should('be.visible').click();
        cy.get("[data-testid='collection-name-table']").contains(collection_title).closest('tr').find("[data-testid='collection-delete-collection-btn']").click();
        cy.intercept('POST', `/admin/collections/*`).as('deleteCollection');
		//May require adding steps to select a collection to move the existing  items, when dealing with non empty collections
		cy.get("[data-testid='collection-delete-confirm-btn']").click()
        cy.wait('@deleteCollection').then((interception) => {
            expect(interception.response.statusCode).to.eq(302);
            expect(interception.response.headers.location).to.include('/admin/collections');
        });
		cy.contains('My Collections');
		//May need to update this assertion to ensure that this is valid during pagination of collections. Another alternative would be to check via API or search My collections
		cy.get("[data-testid='collection-name-table']").contains(collection_title).should('not.exist');
		
	})

})