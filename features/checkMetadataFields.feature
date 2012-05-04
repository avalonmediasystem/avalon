Feature: Check basic metadata fields (form)
  I want to see only certain fields for the simple view
  
  Scenario: Limited fields present
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    Then the form should contain a "title"
    And the form should contain a "date of creation"
    And the form should contain a "creator"
    
