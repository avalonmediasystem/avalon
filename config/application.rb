require_relative 'boot'
require_relative '../lib/tempfile_factory'

require 'rails/all'
require 'resolv-replace'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Avalon
  VERSION = '8.0.1'

  class Application < Rails::Application
    require 'avalon/configuration'

    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # config.autoload_lib(ignore: %w[assets avalon capistrano tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # config.eager_load_paths << Rails.root.join("extras")

    config.active_job.queue_adapter = :sidekiq

    config.action_dispatch.default_headers = { 'X-Frame-Options' => 'ALLOWALL' }

    # We have a number of serializers in place that have not previously had a :coder defined.
    # Setting our global default to the old default :coder should maintain compatibility.
    config.active_record.default_column_serializer = YAML

    # Rails recommends having this set to false, especially in zeitwerk mode. However, that
    # currently causes issues with the Samvera gems (hydra-head, Blacklight)
    config.add_autoload_paths_to_load_path = true

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins { |source| true }
        resource '/avalon_marker/*', headers: :any, credentials: true, methods: [:get, :post, :put, :delete]
        resource '/media_objects/*/manifest*', headers: :any, methods: [:get]
        resource '/master_files/*/thumbnail', headers: :any, methods: [:get]
        resource '/master_files/*/transcript/*', headers: :any, methods: [:get]
        resource '/master_files/*/structure.json', headers: :any, methods: [:get, :post, :delete]
        resource '/master_files/*/waveform.json', headers: :any, methods: [:get]
        resource '/master_files/*/*.m3u8', headers: :any, credentials: true, methods: [:get, :head]
        resource '/master_files/*/captions', headers: :any, methods: [:get]
        resource '/master_files/*/supplemental_files/*', headers: :any, methods: [:get]
        resource '/playlists/*/manifest*', headers: :any, credentials: true, methods: [:get]
        resource '/timelines/*/manifest*', headers: :any, methods: [:get, :post]
        resource '/master_files/*/search', headers: :any, methods: [:get]
        resource '/rails/active_storage/blobs/*/*/*', headers: :any, methods: [:get]
        resource '/rails/active_storage/disk/*/*', headers: :any, methods: [:get]
      end
    end

    config.middleware.insert_before 0, TempfileFactory

    config.active_storage.service = (Settings&.active_storage&.service.presence || "local").to_sym
  end
end
