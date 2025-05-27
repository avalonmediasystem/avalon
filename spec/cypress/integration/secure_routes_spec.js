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

context('Secure routes', () => {
  // '/about' - should provide access to admins
  it('.about_access_admins() - @critical', () => {
    cy.login('administrator')
    cy.visit('/about')
    cy.contains('Environment')
  })

  // '/about' - should not provide access to regular users
  it('.about_access_regular_users() - @critical', () => {
    cy.login('user')
    cy.visit('/about')
    cy.contains('Environment').should('not.exist')
  })

  // '/about' - should not provide access to anonymous users
  it('.about_access_anonymous_users() - @critical', () => {
    cy.visit('/about')
    cy.contains('Environment').should('not.exist')
  })

  // '/about/health' - should provide access to admins
  it('.health_access_admins() - @critical', () => {
    cy.login('administrator')
    cy.visit('/about/health')
    cy.contains('Service Health')
  })

  // '/about/health' - should not provide access to regular users
  it('.health_access_regular_users() - @critical', () => {
    cy.login('user')
    cy.visit('/about/health')
    cy.contains('Service Health').should('not.exist')
  })

  // '/about/health' - should not provide access to anonymous users
  it('.health_access_anonymous_users() - @critical', () => {
    cy.visit('/about/health')
    cy.contains('Service Health').should('not.exist')
  })
})
