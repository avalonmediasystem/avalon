set :output, "log/whenever_cron.log"
job_type :locking_runner, "cd :path && :environment_variable=:environment script/locking_runner :lock_name :task :output"
job_type :locking_rake, "cd :path && :environment_variable=:environment script/locking_runner :lock_name bundle exec rake :task --silent :output"

every 1.minute do
  locking_rake "avalon:batch:ingest", :lock_name => "batch_ingest", :environment => ENV['RAILS_ENV'] || 'production'
end

every 15.minutes do
  locking_rake "avalon:batch:ingest_status_check", :lock_name => "batch_ingest", :environment => ENV['RAILS_ENV'] || 'production'
end

every 1.day do
  locking_rake "avalon:batch:ingest_stalled_check", :lock_name => "batch_ingest", :environment => ENV['RAILS_ENV'] || 'production'
end

every 6.hours do
  rake 'avalon:session_cleanup'
end
