Feature: Create a new object in the system, upload a file, enter basic metadata, and
  then see it appear on the browse page
  
  Scenario: I can create a new record then browse to it
    Given I am logged in as a "cataloger"
    When I create a new video 
    And provide basic metadata for it
    And set the access level to public
    Then I should be able to find the record in the browse view