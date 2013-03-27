set(:rails_env) { "production" }
set(:deployment_host) { "localhost" }  # Host(s) to deploy to
set(:deploy_to) { "/var/www/avalon" }  # Directory to deploy into
set(:user) { 'avalon' }                # User to deploy as
set(:branch) { "bugfix/vov-1397" }     # Git branch to deploy
ssh_options[:keys] = ["/vagrant/files/deployment_key"]

set :bundle_without, [:development,:test]

role :web, "localhost"
role :app, "localhost"
role :db,  "localhost", :primary => true