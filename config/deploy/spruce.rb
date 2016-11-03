set :rails_env, ENV['RAILS_ENV'] || 'development'
set :bundle_flags, '--quiet'
set :bundle_without, fetch(:rails_env) == "development" ? "production" : "development debug"
set :branch, ENV['SCM_BRANCH'] || "develop"
set :hls_dir, "/var/avalon/hls_streams"
server 'spruce.dlib.indiana.edu', roles: %w{web app resque_worker resque_scheduler}, user: 'avalon'
ssh_options[:keys] = ["/opt/staging/avalon/vov_deployment_key"] if ENV['CI_DEPLOY']
append :linked_files, "db/development.sqlite3"
