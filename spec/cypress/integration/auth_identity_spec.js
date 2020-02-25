context('Authentication', () => {

  // Error when creating duplicate user
  it('.duplicate_user_error()', () => {
		cy.visit('/users/sign_up')
		cy.get('form').within(() => {
			cy.get('#user_username').type('test1').should('have.value', 'test1') // Only yield inputs within form
			cy.get('#user_email').type('test1@example.com').should('have.value', 'test1@example.com') // Only yield inputs within form
			cy.get('#user_password').type('test1') // Only yield textareas within form
			cy.get('#user_password_confirmation').type('test1') // Only yield textareas within form
			})
		cy.get('input[name=commit]').last().click()

		cy.visit('/users/sign_up')
		cy.get('form').within(() => {
			cy.get('#user_username').type('test1').should('have.value', 'test1') // Only yield inputs within form
			cy.get('#user_email').type('test1@example.com').should('have.value', 'test1@example.com') // Only yield inputs within form
			cy.get('#user_password').type('test1') // Only yield textareas within form
			cy.get('#user_password_confirmation').type('test1') // Only yield textareas within form
			})
		cy.get('input[name=commit]').last().click()

		cy.contains('prohibited this user from being saved')
  })
})