Feature: Check basic metadata fields (form)
  I want to see only certain fields for the simple view
  
  Scenario: File upload is the first step
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    Then I should be prompted to upload a file

  @javascript
  Scenario: Upload files on catalog edit page
    Given I want to edit "hydrant:short-form-video" as "archivist1@example.com"
    When I upload the file "spec/fixtures/videoshort.mp4" with MIME type "application/MP4"
    Then I should see confirmation that it was uploaded

  Scenario: Basic metadata fields are present in the workflow
    Given I am logged in as "archivist1@example.com"
    And that "hydrant:basic-metadata" has been loaded into fedora
    When I go to the "basic metadata" step for "hydrant:basic-metadata"
    Then I should see only required fields
    
  Scenario: Values persist in the system
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    And provide basic metadata for it
    Then go to the preview screen
    And I should see the changes to the metadata

  Scenario: Deleting an item
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    Then go to the preview screen
    And I delete it
    Then I should see confirmation it has been deleted
