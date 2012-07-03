Feature: Associate bitstreams with an object and return feedback based on the content
  type
  
  @javascript
  Scenario: Upload files on catalog edit page
    Given I want to edit "hydrant:short-form-video" as "archivist1@example.com"
    When I upload the file "spec/fixtures/videoshort.mp4" with MIME type "application/MP4"
    Then I should see confirmation that it was uploaded

  @javascript
  Scenario: The system acknowledges that a file is a video
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    And I upload the file "spec/fixtures/videoshort.mp4" with MIME type "application/mp4"
    Then I should see confirmation that it is video content

  @javascript
  Scenario: The system acknowledges that a file is an audio clip
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    When I upload the file "spec/fixtures/jazz-performance.mp3" with MIME type "audio/mp3"
    Then I should see confirmation that it is audio content

  @javascript
  Scenario: The system acknowledges that a file is invalid (PDF)
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    When I upload the file "spec/fixtures/public-domain-book.pdf" with MIME type "application/PDF"
    Then I should see an error message that the file is not recognized

  @javascript
  Scenario: The system acknowledges that a file is invalid (JPG)
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    When I upload the file "spec/fixtures/fire-hydrant.jpg" with MIME type "image/jpeg"
    Then I should see an error message that the file is not recognized

# Fix this test by figuring out how to confirm the Are you sure? dialog
#  @javascript
#  Scenario: Delete file
#    Given I am logged in as "archivist1@example.com"
#    When I create a new video
#    When I upload the file "spec/fixtures/videoshort.mp4" with MIME type "application/mp4"
#    Then I should see confirmation that it is video content
#    When I delete the file
#    Then I should see confirmation the file has been deleted
    
