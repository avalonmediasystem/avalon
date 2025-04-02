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
  it('.duplicate_user_error()', () => {
		cy.visit('/users/sign_up')
		cy.get('form.new_user').within(() => {
			cy.get('#user_username').type('test1').should('have.value', 'test1') // Only yield inputs within form
			cy.get('#user_email').type('test1@example.com').should('have.value', 'test1@example.com') // Only yield inputs within form
			cy.get('#user_password').type('test1') // Only yield textareas within form
			cy.get('#user_password_confirmation').type('test1') // Only yield textareas within form
			})
		cy.get('input[name=commit]').last().click()

		cy.visit('/users/sign_up')
		cy.get('form.new_user').within(() => {
			cy.get('#user_username').type('test1').should('have.value', 'test1') // Only yield inputs within form
			cy.get('#user_email').type('test1@example.com').should('have.value', 'test1@example.com') // Only yield inputs within form
			cy.get('#user_password').type('test1') // Only yield textareas within form
			cy.get('#user_password_confirmation').type('test1') // Only yield textareas within form
			})
		cy.get('input[name=commit]').last().click()

		cy.contains('prohibited this user from being saved')
  })
})
