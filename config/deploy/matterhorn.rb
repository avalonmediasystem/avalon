set :application, "matterhorn"
set :repository,  "https://github.com/avalonmediasystem/avalon-felix/archive"
set(:rails_env) { "development" }

set(:deployment_host) { "lancelot.dlib.indiana.edu" }  # Host(s) to deploy to
set(:deploy_to) { "/usr/local/matterhorn" }  # Directory to deploy into
set(:user) { 'vov' }                # User to deploy as
set(:branch) { "release/1.0.0" }       # Git branch to deploy
ssh_options[:keys] = ["/opt/staging/avalon/vov_deployment_key"]

set :bundle_without, [:production]

role :web, deployment_host
role :app, deployment_host
role :db, deployment_host, :primary => true

before "deploy:update_code", "deploy:stop"
after "deploy:update_code", "deploy:copy_config"

namespace :deploy do
  task :migrate do
    puts "    not doing migrate because not a Rails application."
  end

  task :update_code do
    run "#{sudo :as => 'matterhorn'} -i -- sh -c 'cd #{deploy_to}; rm -rf current; wget --no-check-certificate #{repository}/#{branch}.zip -O #{application}.zip; unzip #{application}.zip; mv avalon-felix-release-1.0.0 current; rm -f *.zip'"
  end

  task :copy_config do
    run "#{sudo :as => 'matterhorn'} -i -- sh -c 'cd #{deploy_to}; cp shared/config.properties current/etc/'"
  end

  task :create_symlink do
    puts "    not doing create_symlink because not a Rails application."
  end

  task :start do
    sudo "service #{application} start"
  end

  task :stop do 
    sudo "service #{application} stop"
  end

  task :restart do
    sudo "service #{application} restart"
  end
end


