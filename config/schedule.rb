set :output, "log/whenever_cron.log"

every 1.minute do
  rake 'hydrant:batch:ingest', :environment => "development"
end
