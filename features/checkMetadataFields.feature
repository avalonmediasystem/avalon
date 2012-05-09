Feature: Check basic metadata fields (form)
  I want to see only certain fields for the simple view
  
  @create
  Scenario: Limited fields present
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    Then I should see a simple metadata form

  @edit
  Scenario: Values persist in the system
    Given I am logged in as "archivist1@example.com"
    When I edit hydrant:74
    Then I should see the changes to the metadata