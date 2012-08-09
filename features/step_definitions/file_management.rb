# Condense some repeated steps into a single repeatable step
Given /^I want to edit "(.*?)" as a(?:n)? "(.*?)"$/ do |identifier, user_type|
   step "I am logged in as a \"#{user_type}\""
   step "that \"#{identifier}\" has been loaded into fedora"
   # User is spawned when you log in and is available here
   step "that \"#{@user.username}\" can edit \"#{identifier}\""
   step "I edit the \"file upload\" for \"#{identifier}\""
   
   @resource = Video.find(identifier)
end

Then /show me the page/ do
  debug_step(page)
end

When /^I upload the file "(.*?)" with MIME type "(.*)"$/ do |file, mime_type|
  # Look for the file upload field and then attach the file named in the step
  # Next press upload and let the fireworks begins. If there is already a file
  # then delete it
  #
  # This may be an unintended side effect that is better refactored into another
  # location. That will have to wait for a future sprint.
  upload_file("Filedata[]", file, mime_type)  
end

# This is a very brittle test that really needs some refactoring 
Then /^I should see confirmation that it is (audio|video|invalid) content$/ do |format|
  page.wait_until do
    within "#upload_format" do
      unless "invalid" == format
        page.should have_content "appears to be #{format}"
      else
        page.should have_content "content could not be identified"
      end
    end
  end
end

# So is this one
Then /^I should see an error message that the file is not recognized$/ do
  page.wait_until do
    within "#upload_format" do
      page.should have_content "content could not be identified"
    end
  end
end

def upload_file(field, file, mime_type="application/octet-stream")
  page.wait_until do
    attach_file(field, File.expand_path(file))
    
    click_button('Upload file')
  end
end

def debug_step(page)
  logger.debug '<<--->>'
  logger.debug page.current_url
  logger.debug "Saving page to #{page.save_page}"
  logger.debug '<<--->>'
end
