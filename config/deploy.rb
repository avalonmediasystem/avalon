require 'bundler/setup'
require "rvm/capistrano"
require 'bundler/capistrano'
require 'whenever/capistrano'

set :application, "avalon"
set :repository,  "git://github.com/avalonmediasystem/avalon.git"

set :stages, %W(dev testing prod puppet)
set :default_stage, "dev"
require 'capistrano/ext/multistage'

set(:whenever_command) { "bundle exec whenever" }
set(:bundle_flags) { "--quiet --path=#{deploy_to}/shared/gems" }
set :rvm_ruby_string, "ruby-1.9.3-p429"
set :rvm_type, :system

before "deploy", "deploy:log_environment"
before "bundle:install", "deploy:link_local_gemfile"
before "deploy:finalize_update", "deploy:remove_symlink_targets"
after "deploy:update_code", "deploy:migrate"
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
  task :log_environment do
    logger.info "Deploying to #{fetch(:rails_env)}"
  end

	task :remove_symlink_targets do
		shared_children.each do |target|
			t = File.join(latest_release,target)
			run "if [ -f #{t} ]; then rm #{t}; fi"
		end
	end

	task :link_local_gemfile do
		run "if [ -f #{shared_path}/Gemfile.local ]; then ln -s #{shared_path}/Gemfile.local #{latest_release}/Gemfile.local; fi"
	end

	task :trust_rvmrc do
	  run "/usr/local/rvm/bin/rvm rvmrc trust #{latest_release}"
	end

  task :start do
    run "cd #{current_release} && #{rake} RAILS_ENV=#{rails_env} delayed_job:start"
  end

  task :stop do
    run "cd #{current_release} && #{rake} RAILS_ENV=#{rails_env} delayed_job:stop"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_release} && #{rake} RAILS_ENV=#{rails_env} delayed_job:restart"
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
