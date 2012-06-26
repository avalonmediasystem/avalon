When /^I create a new ([^"]*)$/ do |asset_type|
  visit new_video_path
end

# Shortcut for the more verbose step so that the PID does not have to be constantly
# repeated in the feature definitions. 
#
# TO DO : A future enhancement might be to detect the lack of an ID parameters and
#         throw a warning intead of letting it fail fatally.
When /^I go to the "([^"]*)" step$/ do |step|
  id = params[:id]
  step.gsub!(' ', '_')
  
  step "I go to the \"#{step}\" step for \"#{id}\""
end

When /^I go to the "([^"]*)" step for "([^"]*)"$/ do |step, id|
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
  visit edit_video_path(id)
  
  within ('#publication_history_form') do  
    fill_in 'creator', with: 'Rake task'
    fill_in 'title', with: 'Cucumber Test Record'
    fill_in 'created_on', with: '2012.04.21'
    click_on 'Continue'
  end
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
    page.should have_selector("input[name='metadata_title']")
    page.should have_selector("input[name='metadata_creator']")
    page.should have_selector("input[name='metadata_createdon']")
  end
end

# Paths for matching actions that occur when updating an existing record
Then /^I should see the changes to the metadata$/ do
  visit video_path()
  within "#contributors_list" do
    assert page.should have_content('Rake task')
  end

  within "#creation_date" do
    assert page.should have_content('2012.04.21')
  end

  within "h1.document-heading" do
    assert page.should have_content('Cucumber Test Record')
  end
end

def test_for_field(field)
  within ('body') do
    field.gsub!(' ', '_')
    field.downcase!
    
    assert page.has_selector?("\##{field}")
  end
end
