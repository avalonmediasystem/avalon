redis_conn = { url: "redis://#{Settings.redis.host}:#{Settings.redis.port}/" }
Sidekiq.configure_server do |s|
  s.redis = redis_conn
end

Sidekiq.configure_client do |s|
  s.redis = redis_conn
end

# Turn off Sinatra's sessions, which overwrite the main Rails app's session
# after the first request
require 'sidekiq/web'
Sidekiq::Web.disable(:sessions)