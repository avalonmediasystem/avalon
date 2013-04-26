set(:rails_env, ENV['RAILS_ENV'] || "production")
set(:deployment_host) { "localhost" }          # Host(s) to deploy to
set(:deploy_to) { "/var/www/avalon" }          # Directory to deploy into
set(:user) { 'avalon' }                        # User to deploy as
set(:branch, ENV['AVALON_BRANCH'] || "master") # Git branch to deploy
ssh_options[:keys] = ["/opt/staging/avalon/deployment_key"]

set :bundle_without, [:development,:test] if rails_env == 'production'

role :web, "localhost"
role :app, "localhost"
role :db,  "localhost", :primary => true