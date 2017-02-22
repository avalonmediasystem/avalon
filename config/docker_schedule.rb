set :output, "log/whenever_cron.log"
job_type :locking_rake, "source /etc/profile.d/container_environment.sh && cd :path && :environment_variable=:environment script/locking_runner :lock_name bundle exec rake :task --silent :output"

every 1.minute do
  locking_rake "avalon:batch:ingest", :lock_name => "batch_ingest", :environment => ENV['RAILS_ENV'] || 'production'
end
