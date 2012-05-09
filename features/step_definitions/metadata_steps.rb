When /^I create a new ([^"]*)$/ do |asset_type|
  visit path_to("new #{asset_type} page")
end

Then /I should see a simple metadata form/ do 
  test_for_field('title')
  test_for_field('date_of_creation')
  test_for_field('creator')
end

# Paths for matching actions that occur when updating an existing record
When /^I edit (\w*:\d*)$/ do |id|
  visit path_to("the edit page for id #{id}")
  puts page.body
  
  within ('#publication_history_form') do  
    fill_in 'creator', with: 'Rake task'
    fill_in 'title', with: 'Cucumber Test Record'
    fill_in 'date_of_creation', with: '2012.04.21'
    click_on 'Continue'
  end
end

# Paths for matching actions that occur when updating an existing record
Then /^I should see the changes to the metadata$/ do
  click_on 'Switch to browse view'
  assert page.should have_selector('contributors_list').has_content('Rake task')
end

def test_for_field(field)
  within ('form') do
    field.gsub!(' ', '_')
    field.downcase!
    
    assert page.has_selector?("\##{field}")
  end
end
