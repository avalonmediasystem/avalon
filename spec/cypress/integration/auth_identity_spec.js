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

context('Authentication', () => {

  // Error when creating duplicate user
  it('.duplicate_user_error() - @critical', () => {
		cy.visit('/users/sign_up')
		cy.intercept('POST', '/users').as('signup');
		cy.get("[data-testid='sign-up-username']").type('test1').should('have.value', 'test1') // Only yield inputs within form
		cy.get("[data-testid='sign-up-email']").type('test1@example.com').should('have.value', 'test1@example.com') // Only yield inputs within form
		cy.get("[data-testid='sign-up-password']").type('password') // Only yield textareas within form
		cy.get("[data-testid='sign-up-password-confirm']").type('password') // Only yield textareas within form
		
		cy.get("[data-testid='sign-up-btn']").last().click()
		cy.wait('@signup').then((interception) => {
            expect(interception.response.statusCode).to.eq(302);
            
        });
		cy.contains('Sign out').click();

		cy.visit('/users/sign_up')
		cy.intercept('POST', '/users').as('duplicateSignup');
		cy.get("[data-testid='sign-up-username']").type('test1').should('have.value', 'test1') // Only yield inputs within form
		cy.get("[data-testid='sign-up-email']").type('test1@example.com').should('have.value', 'test1@example.com') // Only yield inputs within form
		cy.get("[data-testid='sign-up-password']").type('password') // Only yield textareas within form
		cy.get("[data-testid='sign-up-password-confirm']").type('password') // Only yield textareas within form
			
		cy.get("[data-testid='sign-up-btn']").last().click()

		cy.wait('@duplicateSignup').then((interception) => {
            expect(interception.response.statusCode).to.eq(200);
        });

		cy.contains('prohibited this user from being saved')
  })
//clean up code

  it('Deleting the user created - @critical',()=>{
	cy.login('administrator');
	cy.visit('/persona/users');
	cy.get("[data-testid='users-search-field']").type('test1@example.com');
	cy.get("tr").contains("td", "test1@example.com").should('exist').parent().find("a").contains("Delete").click();
	cy.contains("test1@example.com").should('not.exist');
	cy.get("[data-testid='alert']").contains('User "test1" has been successfully deleted.');
  })

})
