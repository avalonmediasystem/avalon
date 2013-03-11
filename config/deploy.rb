require 'bundler/setup'
require "rvm/capistrano"
require 'bundler/capistrano'
require 'whenever/capistrano'

set :application, "avalon"
set :repository,  "git://github.com/avalonmediasystem/avalon.git"

set :stages, %W(dev testing prod)
set :default_stage, "dev"
require 'capistrano/ext/multistage'

set(:whenever_command) { "bundle exec whenever" }
set(:bundle_flags) { "--quiet --path=#{deploy_to}/shared/gems" }
set :rvm_ruby_string, "1.9.3"
set :rvm_type, :system

after :bundle_install, "deploy:migrate"
after "deploy:create_symlink", "deploy:trust_rvmrc"

set(:shared_children) { 
	%{
		config/authentication.yml 
		config/avalon.yml 
		config/database.yml 
		config/environments 
		config/fedora.yml 
		config/matterhorn.yml 
		config/role_map_#{fetch(:rails_env)}.yml 
		config/solr.yml
		log 
		tmp/pids
	}.split
}

set :scm, :git
set :use_sudo, false
set :keep_releases, 3

task :uname do
  run "uname -a"
end

namespace :deploy do
	task :trust_rvmrc do
	  run "/usr/local/rvm/bin/rvm rvmrc trust #{latest_release}"
	end

  task :start do
    run "cd #{current_release} && bundle exec rake delayed_job:start"
  end

  task :stop do
    run "cd #{current_release} && bundle exec rake delayed_job:stop"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_release} && bundle exec rake delayed_job:restart"
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
