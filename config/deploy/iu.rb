set :rails_env, ENV['RAILS_ENV'] || 'production'
set :bundle_flags, '--quiet'
set :bundle_without, fetch(:rails_env) == "development" ? "production" : "development debug test"
set :branch, ENV['SCM_BRANCH'] || "mco-production"
set :deploy_to, ENV['DEPLOY_TO'] || "/srv/avalon/avalon_r6"
set :hls_dir, ENV['HLS_DIR'] || "/srv/avalon/hls_streams"
server ENV['HOST'] || 'neon.dlib.indiana.edu', roles: %w{web app resque_worker resque_scheduler}, user: 'avalon'
ssh_options[:keys] = ["/opt/staging/avalon/vov_deployment_key"] if ENV['CI_DEPLOY']
