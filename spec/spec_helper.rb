# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = 'test'
require 'simplecov'
SimpleCov.start

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.before(:suite) do
    require 'headless'

    headless = Headless.new
    headless.start
    
    puts "<< headless now running on #{headless.display} >>"
  end


  config.after(:suite) do
    if ENV["USE_HEADLESS"] == "true" and headless.present?
      puts "<< headless now running on #{headless.display} >>"
      headless.destroy
    end
    
    # Put named fixtures from the fixtures directory here so they are cleaned
    # up if they exist
    test_fixtures = ['hydrant:video-segment', 
      'hydrant:electronic-resource',
      'hydrant:musical-performance',
      'hydrant:print-publication']
    test_fixtures.each do |fixture|
      puts "Removing test object #{fixture} if present" 
      MediaObject.find(fixture).delete if MediaObject.exists?(fixture) 
    end
  end
  
  config.include Devise::TestHelpers, :type => :controller
  config.include ControllerMacros, :type => :controller
  config.include FixtureMacros
end
