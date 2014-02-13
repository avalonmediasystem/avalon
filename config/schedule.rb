set :output, "log/whenever_cron.log"
job_type :locking_runner, "cd :path && :environment_variable=:environment script/locking_runner :name :task :output"
job_type :locking_rake, "cd :path && :environment_variable=:environment script/locking_runner :task bundle exec rake :task --silent :output"

every 1.minute do
  locking_rake "avalon:batch:ingest"
end
