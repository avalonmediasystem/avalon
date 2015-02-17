set :application, "matterhorn"
set :git_application, "avalon-felix"
set :repository,  "https://github.com/avalonmediasystem/avalon-felix/archive"

set(:deployment_host) { "lancelot.dlib.indiana.edu" }  # Host(s) to deploy to
set(:deploy_to) { ENV['DEPLOY_DIR'] || "/srv/avalon/matterhorn" }  # Directory to deploy into
set(:user) { 'vov' }                # User to deploy as
set(:branch) { "release/3.0.0" }       # Git branch to deploy
set :branch, ENV['SCM_BRANCH'] if ENV['SCM_BRANCH']

ssh_options[:keys] = ["/opt/staging/avalon/vov_deployment_key"]

role :web, deployment_host
role :app, deployment_host
role :db, deployment_host, :primary => true

before "deploy:update_code", "deploy:stop"
after "deploy:update_code", "deploy:copy_config"

namespace :deploy do
  task :migrate do
    puts "    not doing migrate because not a Rails application.#{deployment_host}"
  end

  task :update_code do
    run "#{sudo :as => 'matterhorn'} -i -- sh -c 'cd #{deploy_to}; rm -rf current; wget --no-check-certificate #{repository}/#{branch}.zip -O #{git_application}.zip; unzip #{git_application}.zip; mv #{git_application}-#{branch.gsub('/', '-')} current; rm -f *.zip'"
  end

  task :copy_config do
    run "#{sudo :as => 'matterhorn'} -i -- sh -c 'cd #{deploy_to}; cp shared/config.properties current/etc/'"
  end

  task :create_symlink do
    puts "    not doing create_symlink because not a Rails application."
  end

  task :symlink_dirs do
    puts "    not doing symlink_dirs because not a Rails application."
  end

  task :trust_rvmrc do
    puts "    not doing trust_rvmrc because not a Rails application."
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
