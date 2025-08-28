config = Rails.application.config

redis_host = Settings.redis.host
redis_port = Settings.redis.port || 6379
redis_db = Settings.redis.db || 0

redis_url = Settings.redis.url || "redis://#{redis_host}:#{redis_port}/#{redis_db}"
config.cache_store = :redis_cache_store, {
  url: redis_url,
  namespace: 'avalon'
}

