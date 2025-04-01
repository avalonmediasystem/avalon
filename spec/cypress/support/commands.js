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
import 'cypress-file-upload';
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
// support/commands.js

Cypress.Commands.add('createItemUnderCollectionUI',(collectionTitle, itemTitle ) => {
  const videoName = "test_sample.mp4";
  const publicationYear = String(Math.floor(Math.random() * (2020 - 1900 + 1)) + 1900);
  
  return cy.wrap(new Promise((resolve, reject) => {
    cy.login('administrator');
    cy.visit('/');
    cy.get('#manageDropdown').click();
    cy.contains('Manage Content').click();
    cy.contains('a', collectionTitle).click();
    cy.contains('a', 'Create An Item').click();
    
    cy.get('div#file-upload input[type="file"][name="Filedata[]"]').selectFile(`spec/cypress/fixtures/${videoName}`, { force: true });
    cy.wait(5000);
    cy.get('div#file-upload a.fileinput-submit').click({ force: true });
    cy.wait(5000);
    cy.get('#associated_files .card-body').should('contain', videoName);
    cy.get('input[name="save_and_continue"][value="Continue"]').click();
    
    cy.get('input#media_object_title').type(itemTitle).should('have.value', itemTitle);
    cy.get('input#media_object_date_issued').type(publicationYear).should('have.value', publicationYear);
    cy.get('input[name="save_and_continue"][value="Save and continue"]').click();
    
    cy.get('li.nav-item.nav-success').contains('a.nav-link', 'Preview').click();
    
    cy.get('.page-title-wrapper h2').should('contain.text', itemTitle);
    
    cy.get('div.ramp--tabs-panel').within(() => {
      cy.get('div.tab-content dt').contains('Date').next('dd').should('have.text', publicationYear);
      cy.get('div.tab-content dt').contains('Collection').next('dd').contains(collectionTitle);
    });
    
    cy.url().then(url => {
      const itemId = url.split('/').pop();
      resolve(itemId);  // Resolve the promise with the item ID
    });
  }));
});
