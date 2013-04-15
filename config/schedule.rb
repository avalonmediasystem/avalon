set :output, "log/whenever_cron.log"

every 1.minute do
  rake 'avalon:batch:ingest'
end
