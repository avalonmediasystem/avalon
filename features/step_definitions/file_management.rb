# Condense some repeated steps into a single repeatable step
Given /^I want to edit "(.*?)" as "(.*?)"$/ do |identifier, user|
   step "I am logged in as \"#{user}\""
   step "that \"#{identifier}\" has been loaded into fedora"
   step "that \"#{user}\" can edit \"#{identifier}\""
   step "I go to the \"file_upload\" step for \"#{identifier}\""
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
  
  # Whoops - no wonder it was failing after this step if the entire asset was being
  # deleted from the repository. This step definitely needs some refinement.
  #
  #if page.has_selector? "#delete_asset"
    #within '#delete_asset' do
    #  click_on('Delete')
    #end
  #
  #end
  upload_file("Filedata[]", file, mime_type)  
end

Then /^I should see confirmation that it was uploaded/ do
  sleep 15
  page.wait_until do
    within "#workflow_status" do
      page.should satisfy {
        |page| page.has_content? "Original file uploaded" or 
          page.has_content? "File is being processed"
      }
    end
  end
end

# This is a very brittle test that really needs some refactoring 
Then /^I should see confirmation that it is (audio|video) content$/ do |format|
  page.wait_until do
    within "#upload_format" do
      page.should have_content "appears to be #{format}"
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
    
    click_button('Upload File')
  end
end

def debug_step(page)
  puts '<<--->>'
  puts page.current_url
  puts "Saving page to #{page.save_page}"
  puts '<<--->>'
end