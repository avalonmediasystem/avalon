When /^I create a new ([^"]*)$/ do |asset_type|
  visit path_to("new #{asset_type} page")
end

When /^the form should contain an? "(.*)"s?$/ do |field|
  within ('form') do
    field.gsub!(' ', '_')
    field.downcase!
    
    puts page.body
    puts "\##{field}"
    
    assert page.has_selector?("\##{field}")
  end
end