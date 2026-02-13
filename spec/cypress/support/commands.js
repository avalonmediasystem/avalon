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
Cypress.Commands.add('login', (role) => {
  cy.clearCookies();
  cy.clearLocalStorage();
  const normalizedRole = role.replace(/_/g, '').toUpperCase();
  const email = Cypress.env('USERS_' + normalizedRole + '_EMAIL');
  const password = Cypress.env('USERS_' + normalizedRole + '_PASSWORD');

  cy.request('/users/sign_in')
    .its('body')
    .then((body) => {
      // thus enabling us to query into it easily
      const $html = Cypress.$(body);
      const csrfToken = $html.find('input[name=authenticity_token]').val();

      cy.request({
        method: 'POST',
        url: '/users/sign_in',
        form: true, 
        body: {
          user: {
            login: email,
            password: password,
          },
          authenticity_token: csrfToken,
        },
      }).then((resp) => {
        expect(resp.status).to.eq(200);
        cy.visit('/');
      });
    });
});

//waits for the media player to be loaded completely
Cypress.Commands.add('waitForVideoReady', () => {
  cy.get('video').should(($video) => {
    const videoEl = $video[0];
    expect(videoEl.readyState).to.be.greaterThan(1);
  });
});
