@file_assets
Feature: Upload file into a document
  In order to add files to a document
  As an editor 
  I want to upload files in the edit form
  
  @nojs
  Scenario: Upload files on catalog edit page
    Given I am logged in as "archivist1@example.com"
		And that "hydrant:318" has been loaded into fedora
		And that "archivist1@example.com" can edit "hydrant:318"
    When I go to the edit document page for hydrant:318
    When I attach the file "spec/fixtures/videoshort.mp4" to "Filedata[]"
    And I press "Upload File"
    Then I should see "(Original file uploaded)" within "#file_status"
