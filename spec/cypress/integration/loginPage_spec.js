<<<<<<< Updated upstream
/* 
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
=======
/*
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
*/

=======
 */
import LoginPage from '../pageObjects/loginPage';
>>>>>>> Stashed changes
import HomePage from '../pageObjects/homePage';

import { signInPage, navigateToPlaylists } from '../support/navigation';
context('Login page', () => {
  const loginPage = new LoginPage();
  const homePage = new HomePage();

  //Do we nned this functions?
  it('Verify if a user is able to log in ', { tags: '@critical' }, () => {
    signInPage();
    loginPage.fillEmail(Cypress.env('USERS_USER_EMAIL'));
    loginPage.fillPassword(Cypress.env('USERS_USER_PASSWORD'));
    loginPage.submit();

    // Assert that user is signed in successfully
    homePage.getLoginSuccessAlert();
  });

  it('should log out successfully ', { tags: '@critical' }, () => {
    cy.login('user');
    // Logout
    homePage.logout();
    // Assert that the login page is visible
    homePage.getLogoutSuccessAlert();
    //assert user can visit the login page from here
    signInPage();
  });

  // validates presence of header and footer on homepage for logged-in user
  it('.sign_in_feature_testing() ', { tags: '@critical' }, () => {
    cy.login('user');
    navigateToPlaylists();
  });

  // validates absence of features when not logged in
  it('.public_user_feature_testing() ', { tags: '@critical' }, () => {
    cy.visit('/');
    cy.contains('Timeline').should('not.exist');
    cy.contains('Playlist').should('not.exist');
    cy.contains('Selected Items').should('not.exist');
    cy.contains('Manage').should('not.exist');
    cy.get('a[href="/users/sign_in"]').should('exist');
  });

  // checks navigation to external links
  it('.external_links() ', { tags: '@critical' }, () => {
    cy.visit('/');
    cy.get(' a[href*="/"] ').first().click();
  });

  // checks navigation to Contact us page
  it('.Contact_us() ', { tags: '@critical' }, () => {
    cy.visit('/');
    cy.contains('Contact Us').click();
    cy.url().should('include', '/comments');
    cy.contains('Name');
    cy.contains('Email address');
    cy.contains('Confirm email address');
    cy.contains('Subject');
    cy.contains('Comment');
    cy.contains('Submit comments');
  });

  // verifies presence of features after login
  it('.feature_verfication_login() ', { tags: '@critical' }, () => {
    cy.login('administrator');
    cy.visit('/');
    cy.contains('Playlists');
    cy.contains('Manage Content');
    cy.contains('Manage Groups');
    cy.contains('Manage Worker Jobs');
    cy.contains('Sign out');
  });

  // Sign in page
  it(
    '.describe_sign_in_page() - click on a DOM element ',
    { tags: '@critical' },
    () => {
      cy.visit('/');
      signInPage();
      cy.contains('Username or email').click();
      cy.contains('Username or email');
      cy.contains('Password');
      cy.contains('Sign up');
      cy.contains('Connect');
    }
  );

  // validates presence of items on register page
  it('.validate_register_page() ', { tags: '@critical' }, () => {
    cy.visit('/users/sign_up');
    cy.contains('Username');
    cy.contains('Email');
    cy.contains('Password');
    cy.contains('Password confirmation');
    cy.contains('Sign up');
  });

  // is able to create new account
  it('.create_new_account() ', { tags: '@critical' }, () => {
    cy.visit('/users/sign_up');
    cy.get('form.new_user').within(() => {
      cy.get('#user_username').type('Sumith').should('have.value', 'Sumith'); // Only yield inputs within form
      cy.get('#user_email')
        .type('sumith3@example.com')
        .should('have.value', 'sumith3@example.com'); // Only yield inputs within form
      cy.get('#user_password').type('sumith3'); // Only yield textareas within form
      cy.get('#user_password_confirmation').type('sumith3'); // Only yield textareas within form
    });
    cy.get('input[name=commit]').last().click();
  });
});
