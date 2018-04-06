# This initializer depends on the cache_store initializer being run first and the cache store being redis
ActiveJob::TrafficControl.client = Redis.new(Rails.application.config.cache_store[1])

