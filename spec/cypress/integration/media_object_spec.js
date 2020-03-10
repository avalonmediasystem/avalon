context('Media objects', () => {

	const media_object_id = Cypress.env('MEDIA_OBJECT_ID')

  // can visit a media object
  it('.visit_media_object()', () => {
		cy.login('administrator')
		// The below code is hard-coded for a media object url. This needs to be changed with a valid object URL later for each website.
		cy.visit('/media_objects/' + media_object_id)
		cy.contains('Unknown item').should('not.exist')
		cy.contains('Beginning Responsibility: Lunchroom Manners')
		cy.contains('Main contributor')
		cy.contains('Date')
		// This below line is to play the video. If the video is not playable, this might return error. In that case, comment the below code.
		cy.get('#mep_0').click()
  })

  // Open multiple media objects in different tabs and play it.
  it.skip('.play_media_objects()', () => {
	  cy.login('administrator')
		cy.visit('/')
		cy.get('a[href*="catalog"] ').first().click()
		//cy.get(' a[href*="/media_objects/"] ').first().click()
		cy.get('a[href*="media_objects').then((media_objects) => {
			function printObject(o) {
				var out = '';
				for (var p in o) {
					out += p + ': ' + o[p] + '\n';
				}
				alert(out);
			}
			var i;
			for (i = 0; i < 3; i += 2) {
				//media_objects[i].click()
				//cy.get('div').should('have.class', 'mejs__overlay-play').first().click()
				window.open(media_objects[i])
				cy.visit(String(media_objects[i]))
				// Below code is to make media play
				cy.window().get('div').should('have.class', 'mejs__overlay-play').first().click({ force: true })
			}
		})
  })
})