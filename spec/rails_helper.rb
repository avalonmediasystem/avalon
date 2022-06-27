# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

# Force test rails environment
ENV['RAILS_ENV'] = 'test'

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  require 'codeclimate-test-reporter'

  SimpleCov.start('rails') do
    add_filter '/spec'
  end
  SimpleCov.command_name 'spec'
end

# Stub out all AWS clients
require 'aws-sdk-core'
require 'aws-sdk-s3'
Aws.config[:stub_responses] = true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
# require 'factory_bot'
require 'capybara/rails'
require 'database_cleaner'
require 'active_fedora/cleaner'
require 'webmock/rspec'
require 'noid/rails/rspec'
require "email_spec"
require "email_spec/rspec"
require 'webdrivers'
# require 'equivalent-xml/rspec_matchers'
# require 'fakefs/safe'
# require 'fileutils'
# require 'tmpdir'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

ActiveJob::Base.queue_adapter = :test

Capybara.server = :webrick
Capybara.server_host = Rails.application.routes.url_helpers.root_url
Capybara.app_host = Rails.application.routes.url_helpers.root_url
Capybara.asset_host = Rails.application.routes.url_helpers.root_url
Capybara.server_port = Rails.application.default_url_options[:port]
Capybara.register_driver :selenium_chrome_headless_docker_friendly do |app|
  Capybara::Selenium::Driver.load_selenium
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(loggingPrefs:{browser: 'ALL'})
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'
  # Sandbox cannot be used inside unprivileged Docker container
  browser_options.args << '--no-sandbox'
  # Next line commented out in favor of before(:each) resize_to that applies to all drivers
  # browser_options.args << '--window-size=1920,1080'
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options, desired_capabilities: caps)
end

# eg `SHOW_BROWSER=true ./bin/rspec` will show you an actual chrome browser
# being operated by capybara.
Capybara.javascript_driver = ENV['SHOW_BROWSER'] ? :selenium_chrome : :selenium_chrome_headless_docker_friendly

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  include Noid::Rails::RSpec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before :suite do
    WebMock.disable_net_connect!(allow: ['localhost', '127.0.0.1', 'fedora', 'fedora-test', 'solr', 'solr-test', 'matterhorn', 'https://chromedriver.storage.googleapis.com'])
    DatabaseCleaner.allow_remote_database_url = true
    DatabaseCleaner.url_allowlist = ['postgres://postgres:password@db/avalon', 'postgresql://postgres@localhost:5432/postgres']
    DatabaseCleaner.clean_with(:truncation)
    ActiveFedora::Cleaner.clean!
    disable_production_minter!

    # Stub the entire dropbox
    Settings.spec = {
      'real_dropbox' => Settings.dropbox.path,
      'fake_dropbox' => Dir.mktmpdir
    }
    Settings.dropbox.path = Settings.spec['fake_dropbox']
    MasterFile.skip_callback(:save, :after, :update_stills_from_offset!)
  end

  config.after :suite do
    if Settings.spec && Settings.spec['fake_dropbox']
      FileUtils.remove_dir Settings.spec['fake_dropbox'], true
      Settings.dropbox.path = Settings.spec['real_dropbox']
      Settings.spec = nil
    end
    enable_production_minter!
    WebMock.allow_net_connect!
  end

  config.before :each do
    DatabaseCleaner.strategy = :truncation
    # Clear out the job queue to ensure tests run with clean environment
    ActiveJob::Base.queue_adapter.enqueued_jobs = []
    ActiveJob::Base.queue_adapter.performed_jobs = []
    Settings.bib_retriever = { 'default' => { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db', 'retriever_class' => 'Avalon::BibRetriever::SRU', 'retriever_class_require' => 'avalon/bib_retriever/sru' } }
  end

  config.after :each do
    DatabaseCleaner.clean
    ActiveFedora::Cleaner.clean!
  end

  config.before(:each, type: :request) do
    host! Rails.application.default_url_options[:host]
  end

  # Remove this check to test on smaller window sizes?
  config.before(:each, js: true) do
    Capybara.page.driver.browser.manage.window.resize_to(1920,1080) # desktop size
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.formatter = 'LdpCallProfileFormatter'
  config.default_formatter = 'doc' if config.files_to_run.one?

  # config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ControllerMacros, type: :controller
  config.include Warden::Test::Helpers,type: :feature
  config.include FixtureMacros, type: :controller
  config.include OptionalExample
end

FactoryBot::SyntaxRunner.class_eval do
  include ActionDispatch::TestProcess
end
