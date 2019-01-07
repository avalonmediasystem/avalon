require_relative 'boot'

require 'rails/all'
require 'resolv-replace'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Avalon
  VERSION = '6.4.5'

  class Application < Rails::Application
    require 'avalon/configuration'

    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.active_job.queue_adapter = :resque

    config.action_dispatch.default_headers = { 'X-Frame-Options' => 'ALLOWALL' }

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/media_objects/*/manifest', headers: :any, methods: [:get]
        resource '/master_files/*/thumbnail', headers: :any, methods: [:get]
        resource '/master_files/*/structure', headers: :any, methods: [:get, :post, :delete]
        resource '/master_files/*/waveform', headers: :any, methods: [:get]
      end
    end
  end
end
