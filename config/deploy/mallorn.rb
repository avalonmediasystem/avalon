set :rails_env, ENV['RAILS_ENV'] || 'development'
set :bundle_flags, '--quiet'
set :bundle_without, fetch(:rails_env) == "development" ? "production" : "development debug"
set :branch, ENV['SCM_BRANCH'] || "develop"
set :deploy_to, ENV['DEPLOY_TO'] || "/srv/avalon/avalon_r6"
set :hls_dir, ENV['HLS_DIR'] || "/srv/avalon/hls_streams"
server 'mallorn.dlib.indiana.edu', roles: %w{web app resque_worker resque_scheduler}, user: 'avalon'
ssh_options[:keys] = ["/opt/staging/avalon/vov_deployment_key"] if ENV['CI_DEPLOY']
append :linked_files, "db/development.sqlite3"
