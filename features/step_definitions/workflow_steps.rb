# This is kludgy but it works - after you spawn a new ID immediately pull it back so
# you can use it in later steps to avoid constantly repeating the identifier
When /^I create a new ([^"]*)$/ do |asset_type|
  visit new_video_path

  @resource = Video.find(:all).last
  puts "<< Storing #{@resource.pid} for later use >>"
  puts "<< #{page.current_url} >>"
  puts "<< #{new_video_path} >>"
end

# Shortcut for the more verbose step so that the PID does not have to be constantly
# repeated in the feature definitions. 
#
# TO DO : A future enhancement might be to detect the lack of an ID parameters and
#         throw a warning intead of letting it fail fatally.
When /^I edit the "([^"]*)"$/ do |step|
  id = params[:id]
  step.gsub!(' ', '_')
  
  step "I go to the \"#{step}\" step for \"#{id}\""
end

When /^I edit the "([^"]*)" for "([^"]*)"$/ do |step, id|
  step.gsub!(' ', '_')
  visit edit_video_path(id, step: step)
end

Then /I should see a simple metadata form/ do 
  test_for_field('metadata_title')
  test_for_field('metadata_createdon')
  test_for_field('metadata_creator')
end

# Paths for matching actions that occur when updating an existing record
When /^I edit "([^"]*)"$/ do |id|
  # Refactor this for be more DRY since it is very similar to the edit methods
  # above
  visit edit_video_path(id, step: 'basic_metadata')
  
  within ('#basic_metadata_form') do  
    fill_in 'metadata_creator', with: 'Cucumber'
    fill_in 'metadata_title', with: 'New test record'
    fill_in 'metadata_createdon', with: '2012.04.21'
    fill_in 'metadata_abstract', with: 'A test record generated as part of Cucumber automated testing'
    click_on 'Save and finish'
  end
end

# Use 'it' as a shortcut in complex steps to retrieve the current PID from the
# active test's scope. This assumes that you have first called the 'create a new'
# step earlier in the sequence
When /^I edit it$/ do
  step "I edit #{@resource.pid}"
end

When /^provide basic metadata for it$/ do 
  # Refactor this for be more DRY since it is very similar to the edit methods
  # above
  visit edit_video_path(@resource.pid, step: 'basic_metadata')
  
  page.driver.render Rails.root.join("tmp/capybara/#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.png")
  
  within ('#basic_metadata_form') do  
    fill_in 'video[creator]', with: 'Cucumber'
    fill_in 'video[title]', with: 'New test record'
    fill_in 'video[created_on]', with: '2012.04.21'
    fill_in 'video[abstract]', with: 'A test record generated as part of Cucumber automated testing'
    click_on 'Continue to access control'
  end
end

When /^I delete it$/ do
  visit video_path(@resource.pid)
  page.driver.render Rails.root.join("tmp/capybara/#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.png")
  click_on 'Delete item'
end

When /^I delete the file$/ do
  visit edit_video_path(@resource.pid, step: 'file-upload')
  click_on 'Delete file'
end

# Refactor this at some point to be more generic instead of quick and dirty
# This also assumes the @resource variable has been set earlier in the session and is
# available for the current test (such as in 'create a new video')
Then /^I should be able to find the record in the browse view$/ do
  visit search_index_path
  
  within '#search_results' do
    test_for_search_result(@resource.pid)
  end
end

Then /^I should be able to search for "(.*)"$/ do |pid|
  visit search_path(q: pid)
  test_for_search_result(@resource.pid)  
end

# Alias for explicit ID which assumes that the PID is in scope at the moment
Then /^I should be able to search for it$/ do
  step "I should be able to search for #{@resource.pid}"
end

Then /^I should be prompted to upload a file$/ do
  within "fieldset#uploader" do
    assert page.should have_content('File Upload')
    assert page.should have_selector('input[type="file"]')
  end
end

# This is not the right test but it is Friday afternoon and my mind can't work
# properly at the moment. It should check for the absence of any fields without the
# required property
Then /^I should see only required fields$/ do 
  within "#basic_metadata_form" do
    page.should have_selector("input[name='video\[title\]']")
    page.should have_selector("input[name='video\[creator\]']")
    page.should have_selector("input[name='video\[created_on\]']")
  end
end

# Paths for matching actions that occur when updating an existing record
Then /^I should see the changes to the metadata$/ do
  visit video_path(@resource.pid) 
  within "#metadata" do
    assert page.should have_content('Cucumber')
    assert page.should have_content('2012.04.21')
    assert page.should have_content('A test record generated as part of Cucumber automated testing')
  end
end

Then /^I should see confirmation that it was uploaded/ do
  visit video_path(@resource.pid)
  page.wait_until do
    within "#workflow_status" do
      page.should satisfy {
        |page| page.has_content? "Preparing file for conversion" or 
          page.has_content? "Creating derivatives"
      }
    end
  end
end

Then /^I should see confirmation it has been deleted$/ do
  within "#marquee" do
    assert page.should have_content("#{@resource.pid} has been deleted from the system")
  end
end

Then /^I should see confirmation the file has been deleted$/ do
  within "#marquee" do
    assert page.should have_content("#{@resource.parts.first.label} has been deleted from the system")
  end
end

Then /^(I )?go to the preview screen/ do |nothing|
  visit video_path(@resource.pid)
end

When /^set the access level to (public|restricted|private)/ do |level|
  visit edit_video_path(@resource, step: 'access_control')
  
  target = "access_" + level
  within '#access_control_form' do
    click target
  end
  click_on 'Preview and publish'
end

def test_for_field(field)
  within ('body') do
    field.gsub!(' ', '_')
    field.downcase!
    
    assert page.has_selector?("\##{field}")
  end
end

def test_for_search_result(pid)
  within ".search-result" do
    logger.debug "<< Testing for presence of #{video_path(pid)} >>"
    
    #assert page.should have_content("a[href='#{link_to video_path(pid)}']")
  end
end
