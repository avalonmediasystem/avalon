Given /^that "([^"]*)" has been loaded into fedora$/ do |pid|
	if Video.exists?(pid)
  	  video = Video.find(pid)
  	  video.parts.each do |part|
    	ActiveFedora::FixtureLoader.delete(part.pid)
  		puts "Deleted #{part.pid}"
  	  end
	end
  
  ActiveFedora::FixtureLoader.new(File.dirname(__FILE__) + '/../../spec/fixtures').reload(pid)
  puts "Refreshed #{pid}"
end

Given /^that "([^"]*)" can edit "([^"]*)"$/ do |email, pid|
	user = User.find_by_email(email)
	ability = Ability.new(user)
	assert ability.can? :edit, pid
end

# Find a select tag on the page
# @param [String] locator Capybara locator
# @return [Capybara::Node]
def find_select(locator)
  no_select_msg = "no select box with id, name, or label '#{locator}' found"
  select = find(:xpath, XPath::HTML.select(locator), :message => no_select_msg)
  return select
end

# Find a select tag on the page and test whether the given value is selected within it
# @param [String] locator Capybara locator for the select tag
# @param [String] value the value that should be selected
def find_and_check_selected_value(locator, value)
  select = find_select(locator)
  no_option_msg = "no option with text '#{value}' in select box '#{locator}'"
  option = select.find(:xpath, XPath::HTML.option(value), :message => no_option_msg)
  option.should be_selected
end
