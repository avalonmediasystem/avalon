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
