config = Rails.application.config

redis_host = Settings.redis.host
redis_port = Settings.redis.port || 6379
redis_db = Settings.redis.db || 0
config.cache_store = :redis_store, {
  host: redis_host,
  port: redis_port,
  db: redis_db,
  namespace: 'avalon'
}

