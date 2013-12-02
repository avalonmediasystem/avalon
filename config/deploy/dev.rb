# These are the configurable bits
set(:rails_env, "development")
set(:deployment_host) { "avalonwebdev.library.northwestern.edu" }  # Host(s) to deploy to
set(:deploy_to) { "/var/www/avalon" }                              # Directory to deploy into
set(:user) { 'avalon' }                                            # User to deploy as
set(:repository) { "git://github.com/nulib/avalon.git" }           # If not using the default avalon repo
set(:branch) { "nu-deploy" }                                       # Git branch to deploy
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_dsa")]    # SSH key used to authenticate as #{ user }

set :bundle_without, [:production]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
