redis_conn = { url: "redis://#{Settings.redis.host}:#{Settings.redis.port}/" }
Sidekiq.configure_server do |s|
  s.redis = redis_conn
end

Sidekiq.configure_client do |s|
  s.redis = redis_conn
end
