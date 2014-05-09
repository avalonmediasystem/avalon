Avalon::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  config.autoload_paths += ["#{Rails.root}/lib"]
  config.autoload_paths += Bundler.load.current_dependencies.map { |dep| 
    if dep.source.is_a?(Bundler::Source::Path) and dep.source.options.has_key?('path')
      dep.to_spec.load_paths#.collect { |path| Dir[File.join(path,'**','*.rb')] }
    end
  }.flatten.compact

  config.log_level = :debug

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true 

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  #config.active_record.mass_assignment_sanitizer = :strict

  # Do not compress assets
  config.assets.compress = true

  # Expands the lines which load the assets
  config.assets.debug = true

  # Keep only five logs and rotate them every 5 MB
  #config.logger = Logger.new(Rails.root.join("log", 
  #  Rails.env + ".log"), 
  #  10, 10*(2**20))
  
  # Configure logging to provide a meaningful context such as the 
  # timestamp and log level. This only works under Rails 3.2.x so if you
  # are using an older version be sure to comment it out
  config.log_tags = ['AVALON',
    :remote_ip,
    Proc.new { Time.now.strftime('%Y.%m.%d %H:%M:%S.%L')}]
   
  config.action_mailer.delivery_method = :letter_opener

  config.eager_load = false

  #config.middleware.insert_before Rails::Rack::Logger, DisableAssetsLogger
end
