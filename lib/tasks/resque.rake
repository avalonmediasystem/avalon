# Monkeypatch of resque to fix ActiveSupport::Concern::MultipleIncludedBlocks when eager_load is false
# Remove when https://github.com/resque/resque/pull/1597 is merged

Rake::Task["resque:preload"].clear_actions
Rake::Task["resque:preload"].enhance do
  if defined?(Rails)
    if Rails::VERSION::MAJOR > 3 && Rails.application.config.eager_load
      ActiveSupport.run_load_hooks(:before_eager_load, Rails.application)
      Rails.application.config.eager_load_namespaces.each(&:eager_load!)

    elsif Rails::VERSION::MAJOR == 3
      ActiveSupport.run_load_hooks(:before_eager_load, Rails.application)
      Rails.application.eager_load!

    elsif defined?(Rails::Initializer)
      $rails_rake_task = false
      Rails::Initializer.run :load_application_classes
    end
  end
end
