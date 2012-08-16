Given /^that "([^"]*)" has been loaded into fedora$/ do |pid|
	if MediaObject.exists?(pid)
  	  media_object = MediaObject.find(pid)
  	  media_object.parts.each do |part|
    	ActiveFedora::FixtureLoader.delete(part.pid)
  		puts "Deleted #{part.pid}"
  	  end
	end
  
  ActiveFedora::FixtureLoader.new(File.dirname(__FILE__) + '/../../spec/fixtures').reload(pid)
  puts "Refreshed #{pid}"
end

Given /^that "([^"]*)" can edit "([^"]*)"$/ do |username, pid|
	user = User.find_by_username(username)
	ability = Ability.new(user)
	assert ability.can? :edit, MediaObject.find(pid)
end
