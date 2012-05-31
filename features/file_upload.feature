@file_assets
Feature: Associate bitstreams with an object and return feedback based on the content
  type
  
  Scenario: Upload files on catalog edit page
    Given I want to edit "hydrant:318" as "archivist1@example.com"
    When I upload the file "spec/fixtures/videoshort.mp4"
    Then I should see confirmation that it was uploaded

  Scenario: The system acknowledges that a file is a video
    Given I want to edit "hydrant:318" as "archivist1@example.com"
    When I upload the file "spec/fixtures/videoshort.mp4"
    Then I should see confirmation that it is video content

  Scenario: The system acknowledges that a file is an audio clip
    Given I want to edit "hydrant:318" as "archivist1@example.com"
    When I upload the file "spec/fixtures/jazz-performance.mp3"
    Then I should see confirmation that it is audio content

  # Still need to write tests to handle unrecognized formats but have run into some
  # issues with testing in Cucumber and odd behaviours    
    
    