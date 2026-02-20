import {
  navigateToManageContent,
  selectCollectionUnit,
} from '../support/navigation.js';
import { getFixturePath } from '../support/utils';
class CollectionPage {
  navigateToCollection(collection_title) {
    navigateToManageContent();
    cy.get("[data-testid='collection-name-table']")
      .contains(collection_title)
      .click();
    cy.url().should('include', '/admin/collections/');
  }

  //creating a collection
  // Basic collection creation - flexible for different needs
  createCollection(collectionData, options = {}) {
    const defaults = {
      description: 'Collection desc',
      contactEmail: 'admin@example.com',
      websiteUrl: 'https://www.google.com',
      websiteLabel: 'test label',
      unitName: 'Automation Unit',
      setPublicAccess: false,
      addManager: false,
    };

    const config = { ...defaults, ...collectionData, ...options };

    // Navigate and start creation
    cy.get("[data-testid='collection-create-collection-button']")
      .contains('Create Collection')
      .click();

    cy.intercept('POST', '/admin/collections').as('createCollection');

    // Fill basic form
    cy.get("[data-testid='collection-name']")
      .type(config.title)
      .should('have.value', config.title);

    selectCollectionUnit(config.unitName);

    cy.get("[data-testid='collection-description']")
      .type(config.description)
      .should('have.value', config.description);

    cy.get("[data-testid='collection-contact-email']")
      .type(config.contactEmail)
      .should('have.value', config.contactEmail);

    cy.get("[data-testid='collection-website-url']")
      .type(config.websiteUrl)
      .should('have.value', config.websiteUrl);

    cy.get("[data-testid='collection-website-label']")
      .type(config.websiteLabel)
      .should('have.value', config.websiteLabel);

    cy.get("[data-testid='collection-new-collection-btn']").click();

    // Handle exceptions
    Cypress.on('uncaught:exception', (err, runnable) => {
      return false;
    });

    // Wait and verify creation
    cy.wait('@createCollection').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include(
        '/admin/collections/'
      );
    });

    // Verify basic creation
    cy.get("[data-testid='collection-collection-details']")
      .contains(config.title)
      .should('be.visible');
    cy.get("[data-testid='collection-edit-collection-info']").should('exist');

    //  (only for item specs)
    if (config.setPublicAccess) {
      this.setPublicAccess();
    }

    // (only for collection specs that need it)
    if (config.addManager) {
      this.addManager(
        config.managerUsername || Cypress.env('USERS_MANAGER_USERNAME')
      );
    }

    return cy.wrap(config.title);
  }

  // Set public access - used by item specs
  setPublicAccess() {
    cy.intercept('POST', '/admin/collections/*').as('updateAccessControl');

    cy.get("[data-testid='collection-item-access']").within(() => {
      cy.contains('label', 'Available to the general public')
        .find("[data-testid='collection-checkbox-general-public']")
        .click()
        .should('be.checked');
      cy.get("[data-testid='collection-save-setting-btn']").click();
    });

    cy.wait('@updateAccessControl').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include(
        '/admin/collections/'
      );
    });

    cy.contains('label', 'Available to the general public')
      .find("[data-testid='collection-checkbox-general-public']")
      .should('be.checked');
  }

  // Add manager - used by collection specs
  addManager(managerUsername) {
    cy.intercept('POST', '/admin/collections/*').as('updateCollectionManager');

    cy.get("[data-testid='add_manager-user-input']")
      .type(managerUsername)
      .should('have.value', managerUsername);

    cy.get("[data-testid='add_manager-popup']")
      .should('be.visible')
      .and('contain', managerUsername)
      .click();

    cy.get("[data-testid='submit-add-manager']").click();

    cy.wait('@updateCollectionManager').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
      expect(interception.response.headers.location).to.include(
        '/admin/collections/'
      );
    });

    cy.get("[data-testid='collection-access-label-manager']")
      .should('exist')
      .contains('label', managerUsername)
      .should('be.visible');
  }

  // Cleanup method for collection created

  deleteCollectionByName(collectionName) {
    navigateToManageContent();
    cy.get('body').then(($body) => {
      if (
        $body.find(
          `[data-testid='collection-name-table']:contains("${collectionName}")`
        ).length > 0
      ) {
        cy.get("[data-testid='collection-name-table']")
          .contains(collectionName)
          .closest('tr')
          .find("[data-testid='collection-delete-collection-btn']")
          .click();

        cy.intercept('POST', `/admin/collections/*`).as('deleteCollection');
        cy.get("[data-testid='collection-delete-confirm-btn']").click();

        cy.wait('@deleteCollection').then((interception) => {
          expect(interception.response.statusCode).to.eq(302);
          expect(interception.response.headers.location).to.include(
            '/admin/collections'
          );
        });

        // Refresh and verify deletion
        navigateToManageContent();
        cy.get("[data-testid='collection-name-table']")
          .contains(collectionName)
          .should('not.exist');
      }
    });
  }

  // Cleanup method for item created

  deleteItemById(itemId) {
    cy.visit('/media_objects/' + itemId);
    cy.waitForVideoReady();
    cy.get('[data-testid="media-object-edit-btn"]').contains('Edit').click();

    cy.intercept('POST', '/media_objects/**').as('removeMediaObject');
    cy.get('[data-testid="media-object-delete-btn"]')
      .contains('Delete this item')
      .click();
    cy.get('[data-testid="media-object-delete-confirmation-btn"]')
      .contains('Yes, I am sure')
      .click();

    cy.wait('@removeMediaObject').then((interception) => {
      expect(interception.response.statusCode).to.eq(302);
    });

    cy.get('[data-testid="alert"]').contains('1 media object deleted.');
  }

  createItem(item_title, videoName) {
    // Create Item button
    cy.intercept('GET', '/media_objects/new?collection_id=*').as(
      'getManageFile'
    );
    cy.get("[data-testid='collection-create-item-btn']")
      .contains('Create An Item')
      .click();
    cy.wait('@getManageFile').its('response.statusCode').should('eq', 302);

    // File upload
    cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect');
    cy.get("[data-testid='media-object-edit-select-file-btn']")
      .click()
      .selectFile(getFixturePath(videoName));
    cy.get("[data-testid='media-object-edit-upload-btn']").click();
    cy.wait('@fileuploadredirect').its('response.statusCode').should('eq', 200);

    cy.get("[data-testid='media-object-edit-associated-files-block']").should(
      'contain',
      videoName
    );

    // Resource description
    cy.intercept('GET', '**/edit?step=resource-description').as(
      'resourcedescription'
    );
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@resourcedescription')
      .its('response.statusCode')
      .should('eq', 200);

    cy.get('[data-testid="resource-description-title"]').type(item_title);
    const publicationYear = String(
      Math.floor(Math.random() * (2020 - 1900 + 1)) + 1900
    );
    cy.get('[data-testid="resource-description-date-issued"]').type(
      publicationYear
    );

    // Structure page
    cy.intercept('GET', '**/edit?step=structure').as('structurepage');
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@structurepage').its('response.statusCode').should('eq', 200);

    // Access control page
    cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@accesspage').its('response.statusCode').should('eq', 200);

    // Complete creation
    cy.get('[data-testid="media-object-continue-btn"]').click();

    // Verify the item details
    cy.get('[data-testid="media-object-title"]').should(
      'contain.text',
      item_title
    );
    cy.get('[data-testid="metadata-display"]').within(() => {
      cy.get('dt')
        .contains('Publication date')
        .next('dd')
        .should('have.text', publicationYear);
    });

    // Return item_id
    return cy.url().then((url) => url.split('/').pop());
  }

  //creates an item with 3 sections (2 videos and 1 audio) adds caption to one video and adds a transcript
  createComplexMediaObject(item_title, options = {}) {
    const defaults = {
      videoFile: 'test_sample.mp4',
      audioFile: 'test_sample_audio.mp3',
      captionFile: 'captions-example.srt',
      addStructure: true,
      publish: true,
    };

    const config = { ...defaults, ...options };

    // Create Item button
    cy.intercept('GET', '/media_objects/new?collection_id=*').as(
      'getManageFile'
    );
    cy.get("[data-testid='collection-create-item-btn']")
      .contains('Create An Item')
      .click();
    cy.wait('@getManageFile').its('response.statusCode').should('eq', 302);

    // Upload first video
    cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect1');
    cy.get("[data-testid='media-object-edit-select-file-btn']")
      .click()
      .selectFile(getFixturePath(config.videoFile));
    cy.get("[data-testid='media-object-edit-upload-btn']").click();
    cy.wait('@fileuploadredirect1')
      .its('response.statusCode')
      .should('eq', 200);
    cy.get("[data-testid='media-object-edit-associated-files-block']").should(
      'contain',
      '.mp4'
    );

    // Add caption to first video
    cy.get('[data-testid="media-object-manage-files-edit-btn"]').click();
    cy.get('[data-testid="media-object-upload-button-caption"]').selectFile(
      getFixturePath(config.captionFile),
      { force: true }
    );
    cy.get('[data-testid="alert"]').contains(
      'Supplemental file successfully added.'
    );

    // Upload audio file
    cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect2');
    cy.get("[data-testid='media-object-edit-select-file-btn']")
      .click()
      .selectFile(getFixturePath(config.audioFile));
    cy.get("[data-testid='media-object-edit-upload-btn']").click();
    cy.wait('@fileuploadredirect2')
      .its('response.statusCode')
      .should('eq', 200);
    cy.get("[data-testid='media-object-edit-associated-files-block']").should(
      'contain',
      '.mp3'
    );

    // Upload third video
    cy.intercept('GET', '**/edit?step=file-upload').as('fileuploadredirect3');
    cy.get("[data-testid='media-object-edit-select-file-btn']")
      .click()
      .selectFile(getFixturePath(config.videoFile));
    cy.get("[data-testid='media-object-edit-upload-btn']").click();
    cy.wait('@fileuploadredirect3')
      .its('response.statusCode')
      .should('eq', 200);
    cy.get("[data-testid='media-object-edit-associated-files-block']").should(
      'contain',
      '.mp4'
    );

    // Continue to resource description
    cy.intercept('GET', '**/edit?step=resource-description').as(
      'resourcedescription'
    );
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@resourcedescription')
      .its('response.statusCode')
      .should('eq', 200);

    // Fill resource description
    cy.get('[data-testid="resource-description-title"]')
      .type(item_title)
      .should('have.value', item_title);

    const publicationYear = String(
      Math.floor(Math.random() * (2020 - 1900 + 1)) + 1900
    );
    cy.get('[data-testid="resource-description-date-issued"]')
      .type(publicationYear)
      .should('have.value', publicationYear);

    // Continue to structure page
    cy.intercept('GET', '**/edit?step=structure').as('structurepage');
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@structurepage').its('response.statusCode').should('eq', 200);

    // Add structure if requested (via file upload)
    if (config.addStructure) {
      cy.get(`[data-testid="media-object-struct-upload-btn-0"]`)
        .should('be.visible').and('contain.text', 'Upload');

      cy.intercept('POST', '**/attach_structure').as('saveStructure');

      // Upload the file using the respective file input
      cy.get(`#structure_0_filedata`).selectFile(
        getFixturePath('test-sample.mp4.structure.xml'),
        { force: true }
      );

      // Wait for the API call to complete
      cy.wait('@saveStructure').its('response.statusCode').should('eq', 302);

      // Verify the button text has changed to "Replace"
      cy.get(`[data-testid="media-object-struct-upload-btn-0"]`)
        .should('be.visible')
        .and('contain.text', 'Replace');
    }

    // Continue to access control
    cy.intercept('GET', '**/edit?step=access-control').as('accesspage');
    cy.get('[data-testid="media-object-continue-btn"]').click();
    cy.wait('@accesspage').its('response.statusCode').should('eq', 200);

    // Skip access control
    cy.get('[data-testid="media-object-continue-btn"]').click();

    // Verify creation
    cy.get('[data-testid="media-object-title"]').should(
      'contain.text',
      item_title
    );
    cy.get('[data-testid="metadata-display"]').within(() => {
      cy.get('dt')
        .contains('Publication date')
        .next('dd')
        .should('have.text', publicationYear);
    });

    // Extract item ID and store it
    cy.url().then((url) => {
      const itemId = url.split('/').pop();

      // Publish if requested
      if (config.publish) {
        cy.intercept('POST', '**/update_status?status=publish').as(
          'publishmedia'
        );
        cy.get('[data-testid="media-object-publish-btn"]')
          .contains('Publish')
          .click();
        cy.wait('@publishmedia').its('response.statusCode').should('eq', 302);
        cy.get('[data-testid="alert"]').contains(
          'Media object successfully published.'
        );
        cy.wait(2000);
        cy.get('[data-testid="media-object-unpublish-btn"]').contains(
          'Unpublish'
        );
      }

      // Store the ID in a global variable instead of returning
      cy.wrap(itemId).as('mediaObjectId');
    });

    // Return the alias so it can be used
    return cy.get('@mediaObjectId');
  }
}

export default CollectionPage;
