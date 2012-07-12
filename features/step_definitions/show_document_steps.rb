require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

# Keep these two for now until they can be refactored in a more useful
# location along with other helper methods
Then /^I should see a link to "([^\"]*)"$/ do |link_path|
  page.should have_xpath(".//a[@href=\"#{path_to(link_path)}\"]")
end

Then /^I should not see a link to "([^\"]*)"$/ do |link_path|
  page.should_not have_xpath(".//a[@href=\"#{path_to(link_path)}\"]")
end
