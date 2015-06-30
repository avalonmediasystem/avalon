# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = 'test'
require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'rspec/its'
require 'equivalent-xml/rspec_matchers'
require 'capybara/rspec'
require 'database_cleaner'
require 'fakefs/safe'
require 'fileutils'
require 'tmpdir'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/models/shared_examples/**/*.rb")].each {|f| require f}

Avalon::GROUP_LDAP = Net::LDAP.new unless defined?(Avalon::GROUP_LDAP)
Avalon::GROUP_LDAP_TREE = 'ou=Test,dc=avalonmediasystem,dc=org' unless defined?(Avalon::GROUP_LDAP_TREE)

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
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.infer_spec_type_from_file_location!

  config.before(:suite) do
    DatabaseCleaner[:active_record].strategy = :deletion
    DatabaseCleaner[:active_fedora].strategy = :deletion
    DatabaseCleaner.clean
    Rails.cache.clear 
    Deprecation.default_deprecation_behavior = :silence

    # Stub the entire dropbox
    Avalon::Configuration['spec'] = {
      'real_dropbox' => Avalon::Configuration.lookup('dropbox.path'),
      'fake_dropbox' => Dir.mktmpdir
    }
    Avalon::Configuration['dropbox']['path'] = Avalon::Configuration.lookup('spec.fake_dropbox')

    ActiveEncode::Base.engine_adapter = :test
    
    server_options = { host: 'test.host', port: nil }
    Rails.application.routes.default_url_options.merge!( server_options )
    ActionMailer::Base.default_url_options.merge!( server_options )
    ApplicationController.default_url_options = server_options
  end

  config.after(:suite) do
    if Avalon::Configuration.lookup('spec.fake_dropbox')
      FileUtils.remove_dir Avalon::Configuration.lookup('spec.fake_dropbox'), true
      Avalon::Configuration['dropbox']['path'] = Avalon::Configuration.lookup('spec.real_dropbox')
      Avalon::Configuration.delete('spec')
    end
  end

  config.before(:each) do
    Rails.cache.clear
    DatabaseCleaner.start
    RoleMap.reset!
    Admin::Collection.stub(:units).and_return ['University Archives', 'University Library']
  end

  config.after(:each) do
    Rails.cache.clear
    DatabaseCleaner.clean
   end 

  config.include Devise::TestHelpers, :type => :controller
  config.include ControllerMacros, :type => :controller
  config.include FixtureMacros
end
