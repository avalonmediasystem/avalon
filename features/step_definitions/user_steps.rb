# @example
#   I log in as "archivist1@example.com"
# @example
#   I am logged in as "archivist1@example.com"
Given /^I (?:am )?log(?:ged)? in as "([^\"]*)"$/ do |username|

  @current_user = User.create!(:username => username)
  login_as(@current_user, :scope => :user)

  visit root_path

  step %{I should see a link to "logout"} 
end

Given /^I am logged in as "([^\"]*)" with "([^\"]*)" permissions$/ do |login,permission_group|
  Given %{I am logged in as "#{login}"}
  RoleMapper.roles(login).should include permission_group
end

Given /^I am a superuser$/ do
  step %{I am logged in as "bigwig@example.com"}
  bigwig_id = User.find_by_username("bigwig@example.com").id
  superuser = Superuser.find_by_user_id(bigwig_id)
  unless superuser
    superuser = Superuser.new()
    superuser.id = 20
    superuser.user_id = bigwig_id
    superuser.save!
  end
  visit superuser_path
end

Given /^I am not logged in$/ do
  step %{I log out}
end

Given /^I log out$/ do
  logout(:scope => :user)
#  visit destroy_user_session_path
end
