# These are the configurable bits
set(:rails_env) { "production" }
set(:deployment_host) { "192.168.56.2" } 													   # Host(s) to deploiy to
set(:deploy_to) { "/var/www/avalon" }                                # Directory to deploy into
set(:user) { 'avalon' }                                              # User to deploy as
set(:repository) { "git://github.com/avalonmediasystem/avalon.git" } # If not using the default avalon repo
set(:branch) { "bugfix/vov-1397" }                                   # Git branch to deploy
ssh_options[:keys] = [File.join(ENV["HOME"], ".vagrant.d", 
	"insecure_private_key")]      																		 # SSH key used to authenticate as #{ user }

set :bundle_without, [:development,:test]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true