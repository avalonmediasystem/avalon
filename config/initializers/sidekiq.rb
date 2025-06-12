redis_url = Settings.redis.url || "redis://#{Settings.redis.host}:#{Settings.redis.port}/#{Settings.redis.db}"
redis_conn = { url: redis_url }
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

require 'sidekiq/cron/web'
Rails.application.config.to_prepare do
  begin
    # Only create cron jobs if Sidekiq can connect to Redis
    Sidekiq.redis(&:info)
    Sidekiq::Cron::Job.create(name: 'Scan for batches - every 1min', cron: '*/1 * * * *', class: 'BatchScanJob')
    Sidekiq::Cron::Job.create(name: 'Status Checking and Email Notification of Existing Batches - every 15min', cron: '*/15 * * * *', class: 'IngestBatchStatusEmailJobs::IngestFinished')
    Sidekiq::Cron::Job.create(name: 'Status Checking and Email Notification for Stalled Batches - every 1day', cron: '0 1 * * *', class: 'IngestBatchStatusEmailJobs::StalledJob')
    Sidekiq::Cron::Job.create(name: 'Clean out user sessions older than 7 days - every 6hour', cron: '0 */6 * * *', class: 'CleanupSessionJob')
    Sidekiq::Cron::Job.create(name: 'Clean out expired stream tokens - every 5min', cron: '*/5 * * * *', class: 'CleanupStreamTokenJob')
  rescue Redis::CannotConnectError => e
    Rails.logger.warn "Cannot create sidekiq-cron jobs: #{e.message}"
  end
end
