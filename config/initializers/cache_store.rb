config = Rails.application.config

redis_host = Settings.redis.host
redis_port = Settings.redis.port || 6379
config.cache_store = :redis_store, {
  host: redis_host,
  port: redis_port,
  db: 0,
  namespace: 'avalon'
}

