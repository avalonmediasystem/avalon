import HomePage from '../pageObjects/homePage';
const homePage = new HomePage();
class ItemPage {
  verifyAccessible(item_id) {
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
  }

  verifyInaccessible(item_id) {
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id, { failOnStatusCode: false });
    cy.wait(2000);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(401);
    });
  }

  verifyCollecttionStaffAccess(item_id) {
    //login as a user who is a staff to the collection and verify that the item is accessible
    cy.login('unit_manager');
    this.verifyAccessible(item_id);

    //Login as a user who is not a staff to collection to validate the result
    cy.login('user');
    this.verifyInaccessible(item_id);

    //without log in
    homePage.logout();
    this.verifyInaccessible(item_id);
  }

  verifyLoggedInUserAccess(item_id) {
    //login as a user who is a staff to the collection and verify that the item is accessible
    cy.login('unit_manager');
    this.verifyAccessible(item_id);

    //Login as a user who is not a staff to collection to validate the result
    cy.login('user');
    this.verifyAccessible(item_id);

    //without log in
    homePage.logout();
    this.verifyInaccessible(item_id);
  }

  verifyGeneralPublicAccess(item_id) {
    //login as a user who is a staff to the collection and verify that the item is accessible
    cy.login('unit_manager');
    this.verifyAccessible(item_id);

    //Login as a user who is not a staff to collection to validate the result
    cy.login('user');
    this.verifyAccessible(item_id);

    //without log in
    homePage.logout();
    this.verifyAccessible(item_id);
  }

  publishItem(item_id) {
    cy.visit('/media_objects/' + item_id);
    cy.intercept('POST', '**/update_status?status=publish').as(
      'publishmedia',
    );
    cy.get('[data-testid="media-object-publish-btn"]')
      .contains('Publish')
      .click();
    cy.wait('@publishmedia').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });
    //validate success message
    cy.get('[data-testid="alert"]').contains(
      'Media object successfully published.',
    );
  }

  unpublishItem(item_id) {
    cy.visit('/media_objects/' + item_id);
    cy.intercept('POST', '**/update_status?status=unpublish').as(
      'unpublishmedia',
    );
    cy.get('[data-testid="media-object-unpublish-btn"]')
      .contains('Unpublish')
      .click();
    cy.wait('@unpublishmedia').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });
    //validate success message
    cy.get('[data-testid="alert"]').contains(
      'Media object successfully unpublished.',
    );
  }

  ensurePublishStatus(item_id, publishStatus) {
    cy.request('/media_objects/' + item_id + '.json').then((response) => {
      expect(response.status).to.eq(200);
      var published = response.body.published;
      cy.log("Found publishStatus: " + published);

      if (published == publishStatus) return;

      if (publishStatus == true) {
        cy.log("Unpublished so publishing...");
        this.publishItem(item_id);
      } else {
        cy.log("Published so Unpublishing...");
        this.unpublishItem(item_id);
      }
    });
  }
}
export default ItemPage;
