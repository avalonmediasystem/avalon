Feature: Associate bitstreams with an object and return feedback based on the content
  type
  
  @javascript
  Scenario: Upload files on catalog edit page
    Given I want to edit "hydrant:318" as "archivist1@example.com"
    When I upload the file "spec/fixtures/videoshort.mp4"
    Then I should see confirmation that it was uploaded

  @javascript
  Scenario: The system acknowledges that a file is a video
    Given I want to edit "hydrant:318" as "archivist1@example.com"
    When I upload the file "spec/fixtures/videoshort.mp4"
    Then I should see confirmation that it is video content

  @javascript
  Scenario: The system acknowledges that a file is an audio clip
    Given I want to edit "hydrant:318" as "archivist1@example.com"
    When I upload the file "spec/fixtures/jazz-performance.mp3"
    Then I should see confirmation that it is audio content

  @javascript
  Scenario: The system acknowledges that a file is invalid (PDF)
    Given I want to edit "hydrant:318" as "archivist1@example.com"
    When I upload the file "spec/fixtures/public-domain-book.pdf"
    Then I should see an error message that the file is not recognized

  @javascript
  Scenario: The system acknowledges that a file is invalid (JPG)
    Given I want to edit "hydrant:318" as "archivist1@example.com"
    When I upload the file "spec/fixtures/fire-hydrant.jpg"
    Then I should see an error message that the file is not recognized
    
    