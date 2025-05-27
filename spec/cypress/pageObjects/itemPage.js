import HomePage from '../pageObjects/homePage';
const homePage = new HomePage();
class ItemPage {
  verifyCollecttionStaffAccess(item_id) {
    homePage.logout();

    //login as a user who is a staff to the collection and verify that the item is accessible
    cy.login('manager');
    cy.visit('/');
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

    homePage.logout();
    //Login as a user who is not a staff to collection to validate the result
    cy.login('user');
    cy.visit('/');
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id, { failOnStatusCode: false });
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(401);
    });

    //without log in
    homePage.logout();
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id, { failOnStatusCode: false });
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(401);
    });
  }

  verifyLoggedInUserAccess(item_id) {
    homePage.logout();

    //login as a user who is a staff to the collection and verify that the item is accessible
    cy.login('manager');
    cy.visit('/');
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

    homePage.logout();
    //Login as a user who is not a staff to collection to validate the result
    cy.login('user');
    cy.visit('/');
    cy.intercept('GET', '/media_objects/*').as('getmediaobject1');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject1').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

    //without log in
    homePage.logout();
    cy.intercept('GET', '/media_objects/*').as('getmediaobject2');
    cy.visit('/media_objects/' + item_id, { failOnStatusCode: false });
    cy.wait('@getmediaobject2').then((interception) => {
      expect(interception.response.statusCode).to.eq(401);
    });
  }

  verifyGeneralPublicAccess(item_id) {
    homePage.logout();

    //login as a user who is a staff to the collection and verify that the item is accessible
    cy.login('manager');
    cy.visit('/');
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

    homePage.logout();
    //Login as a user who is not a staff to collection to validate the result
    cy.login('user');
    cy.visit('/');
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });

    //without log in
    homePage.logout();
    cy.intercept('GET', '/media_objects/*').as('getmediaobject');
    cy.visit('/media_objects/' + item_id);
    cy.wait('@getmediaobject').then((interception) => {
      expect(interception.response.statusCode).to.eq(200);
    });
  }
}
export default ItemPage;
