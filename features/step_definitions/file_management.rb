# Condense some repeated steps into a single repeatable step
Given /^I want to edit "(.*?)" as "(.*?)"$/ do |identifier, user|
   step "I am logged in as \"#{user}\""
   step "that \"#{identifier}\" has been loaded into fedora"
   step "that \"#{user}\" can edit \"#{identifier}\""
   step "I go to the edit document page for #{identifier}"
end

Then /show me the page/ do
  puts page.html
end

When /^I upload the file "(.*?)"$/ do |file|
  # Look for the file upload field and then attach the file named in the step
  # Next press upload and let the fireworks begins. If there is already a file
  # then delete it
  #
  # This may be an unintended side effect that is better refactored into another
  # location. That will have to wait for a future sprint.
  if page.has_selector? "#delete_asset"
    within '#delete_asset' do
      click_on('Delete')
    end
  end
  
  attach_file("Filedata[]", file)
  click_button('Upload File')
end

Then /^I should see confirmation that it was uploaded/ do
  within "#file_status" do
    page.should have_content "File is being processed in Matterhorn"
  end
end

# This is a very brittle test that really needs some refactoring 
Then /^I should see confirmation that it is (audio|video) content$/ do |format|
  puts page.html
  within "#upload_status" do
    page.should have_content "appears to be #{format}"
  end
end

# So is this one
Then /^I should an error message that the file is not recognized$/ do
  within "#upload_status" do
    page.should have_content "format is not recognized"
  end
end
