Feature: Check basic metadata fields (form)
  I want to see only certain fields for the simple view
  
  Scenario: File upload is the first step
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    Then I should be prompted to upload a file

  Scenario: Basic metadata fields are present in the workflow
    Given I am logged in as "archivist1@example.com"
    And I go to the "basic metadata" step for "hydrant:basic-metadata"
    Then I should see only required fields
    
  # Temporarily disabled until the 'browse' link comes back next week
  #Scenario: Values persist in the system
  #  Given I am logged in as "archivist1@example.com"
  #  And that "hydrant:basic-metadata" has been loaded into fedora
  #  When I edit "hydrant:basic-metadata"
  #  Then I should see the changes to the metadata
