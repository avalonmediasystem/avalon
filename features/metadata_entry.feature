Feature: Check basic metadata fields (form)
  I want to see only certain fields for the simple view
    
  # Rewrite this as an RSpec test that creates a new item, injects the
  # metadata, and then looks at the OM to see if the values persist
  @wip
  Scenario: Values persist in the system
    Given I am logged in as a "cataloger"
    When I create a new media object
    And provide basic metadata for it
    Then go to the preview screen
    And I should see the changes to the metadata

  @wip
  Scenario: Deleting an item
    Given I am logged in as a "cataloger"
    When I create a new media object
    Then go to the preview screen
    And I delete it
    Then I should see confirmation it has been deleted
