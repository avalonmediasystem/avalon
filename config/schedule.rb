set :output, "log/whenever_cron.log"

every 1.minute, :roles => [:app] do
  rake 'avalon:batch:ingest'
end
