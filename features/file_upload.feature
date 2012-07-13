Feature: Associate bitstreams with an object and return feedback based on the content
  type
  
  @javascript
  Scenario Outline: The system acknowledges the format of a file
    Given I am logged in as "archivist1@example.com"
    When I create a new video
    And I upload the file "<file>" with MIME type "<mimetype>"
    Then I should see confirmation that it is <format> content

  Scenarios: Video content
    | format | file | mimetype |
    | video  | spec/fixtures/videoshort.mp4 | application/mp4 |
    | audio  | spec/fixtures/videoshort.mp4 | application/mp4 |
    
  Scenarios: Audio content
    | format | file | mimetype |
    | audio  | spec/fixtures/jazz-performance.mp3 | audio/mp3 |

  Scenarios: Invalid files
    | format | file | mimetype |
    | invalid | spec/fixtures/public-domain-book.pdf | application/PDF |
    | invalid | spec/fixtures/fire-hydrant.jpg | image/jpeg |
