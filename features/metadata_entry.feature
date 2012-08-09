Feature: Check basic metadata fields (form)
  I want to see only certain fields for the simple view
  
  Scenario: File upload is the first step
    Given I am logged in as a "cataloger"
    When I create a new video
    Then I should be prompted to upload a file

  Scenario: Basic metadata fields are present in the workflow
    Given I am logged in as a "cataloger"
    And that "hydrant:basic-metadata" has been loaded into fedora
    When I edit the "basic metadata" for "hydrant:basic-metadata"
    Then I should see only required fields
    
  Scenario: Values persist in the system
    Given I am logged in as a "cataloger"
    When I create a new video
    And provide basic metadata for it
    Then go to the preview screen
    And I should see the changes to the metadata

  Scenario: Deleting an item
    Given I am logged in as a "cataloger"
    When I create a new video
    Then go to the preview screen
    And I delete it
    Then I should see confirmation it has been deleted
