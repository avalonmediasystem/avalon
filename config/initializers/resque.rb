rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'

if ENV['REDIS_SERVER'].present?
  Resque.redis = ENV['REDIS_SERVER']
else
  resque_config = YAML.load_file(rails_root + '/config/resque.yml')
  Resque.redis = resque_config[rails_env]
end

# Enable schedule tab in Resque web ui
require 'resque-scheduler'
require 'resque/scheduler/server'
