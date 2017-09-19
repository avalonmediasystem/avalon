require 'coveralls'
Coveralls.wear!

if ENV['COVERAGE'] || ENV['TRAVIS']
  require 'simplecov'
  SimpleCov.root(File.expand_path('..', __FILE__))
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start('rails') do
    add_filter '/spec'
  end
  SimpleCov.command_name 'spec'
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
# require 'factory_girl'
require 'capybara/rails'
require 'database_cleaner'
require 'active_fedora/cleaner'
require 'webmock/rspec'
require 'active_fedora/noid/rspec'
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

ActiveJob::Base.queue_adapter = :inline

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  include ActiveFedora::Noid::RSpec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before :suite do
    WebMock.disable_net_connect!(allow: ['localhost', '127.0.0.1', 'fedora', 'solr', 'matterhorn'])
    DatabaseCleaner.clean_with(:truncation)
    ActiveFedora::Cleaner.clean!
    disable_production_minter!

    # Stub the entire dropbox
    Avalon::Configuration['spec'] = {
      'real_dropbox' => Avalon::Configuration.lookup('dropbox.path'),
      'fake_dropbox' => Dir.mktmpdir
    }
    Avalon::Configuration['dropbox']['path'] = Avalon::Configuration.lookup('spec.fake_dropbox')
    MasterFile.skip_callback(:save, :after, :update_stills_from_offset!)
  end

  config.after :suite do
    if Avalon::Configuration.lookup('spec.fake_dropbox')
      FileUtils.remove_dir Avalon::Configuration.lookup('spec.fake_dropbox'), true
      Avalon::Configuration['dropbox']['path'] = Avalon::Configuration.lookup('spec.real_dropbox')
      Avalon::Configuration.delete('spec')
    end
    enable_production_minter!
    WebMock.allow_net_connect!
  end

  config.before :each do
    DatabaseCleaner.strategy = :truncation
  end

  config.after :each do
    DatabaseCleaner.clean
    ActiveFedora::Cleaner.clean!
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

  # config.include FactoryGirl::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ControllerMacros, type: :controller
  config.include Warden::Test::Helpers,type: :feature
  config.include FixtureMacros, type: :controller
  config.include OptionalExample
end
