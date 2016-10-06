set :output, "log/whenever_cron.log"
job_type :locking_runner, "cd :path && :environment_variable=:environment script/locking_runner :lock_name :task :output"
job_type :locking_rake, "cd :path && :environment_variable=:environment script/locking_runner :lock_name bundle exec rake :task --silent :output"

every 1.minute do
  locking_rake "avalon:batch:ingest", :lock_name => "batch_ingest"
end
