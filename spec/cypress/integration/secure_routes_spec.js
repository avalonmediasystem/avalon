context('Secure routes', () => {
  // '/about' - should provide access to admins
  it('.about_access_admins()', () => {
    cy.login('administrator')
    cy.visit('/about')
    cy.contains('Environment')
  })

  // '/about' - should not provide access to regular users
  it('.about_access_regular_users()', () => {
    cy.login('user')
    cy.visit('/about')
    cy.contains('Environment').should('not.exist')
  })

  // '/about' - should not provide access to anonymous users
  it('.about_access_anonymous_users()', () => {
    cy.visit('/about')
    cy.contains('Environment').should('not.exist')
  })

  // '/about/health' - should provide access to admins
  it('.health_access_admins()', () => {
    cy.login('administrator')
    cy.visit('/about/health')
    cy.contains('Service Health')
  })

  // '/about/health' - should not provide access to regular users
  it('.health_access_regular_users()', () => {
    cy.login('user')
    cy.visit('/about/health')
    cy.contains('Service Health').should('not.exist')
  })

  // '/about/health' - should not provide access to anonymous users
  it('.health_access_anonymous_users()', () => {
    cy.visit('/about/health')
    cy.contains('Service Health').should('not.exist')
  })
})