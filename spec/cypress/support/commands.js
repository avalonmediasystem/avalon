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

// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
Cypress.Commands.add("login", (role) => {
  const email = Cypress.env('USERS_' + role.toUpperCase() + '_EMAIL')
  const password = Cypress.env('USERS_' + role.toUpperCase() + '_PASSWORD')

  cy.request('/users/sign_in')
  .its('body')
  .then((body) => {
    // we can use Cypress.$ to parse the string body
    // thus enabling us to query into it easily
    const $html = Cypress.$(body)
    const csrfToken = $html.find('input[name=authenticity_token]').val()

    cy.request({
      method: 'POST',
      url: '/users/sign_in',
      body: {
        user: {
          login: email,
          password: password,
        },
        authenticity_token: csrfToken,
      }
    }).then((resp) => {
      expect(resp.status).to.eq(200)
    })
  })
})
//
//
// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })
