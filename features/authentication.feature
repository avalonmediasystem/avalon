Feature: Check authorization protects certain controller actions
  I want only authorized users to be able to perform priviledged actions

  Scenario: Item creation - authenticated and authorized
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    Then I should be prompted to upload a file

  Scenario: Item creation - authenticated and unauthorized
    Given I am logged in as "patron1@example.com"
    When I create a new video
    Then I should be on the home page

  Scenario: Item creation - unauthenticated and unauthorized
    Given I am not logged in
    When I create a new video
    Then I should be on the sign in page

  Scenario: Add new item - authenticated and authorized
    Given I am logged in as "archivist1@example.com"
    And I visit the home page
    When I follow "Add new item"
    And I should be prompted to upload a file

  Scenario: Add new item - authenticated and unauthorized
    Given I am logged in as "patron1@example.com"
    And I visit the home page
    When I follow "Add new item"
    Then I should be on the home page

  Scenario: Add new item - unauthenticated and unauthorized
    Given I am not logged in
    And I visit the home page
    When I follow "Add new item"
    Then I should be on the sign in page
