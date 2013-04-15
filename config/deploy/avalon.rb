set :application, "avalon"
set :repository,  "git://github.com/avalonmediasystem/avalon.git"
set(:rails_env) { "development" }

set(:deployment_host) { "lancelot.dlib.indiana.edu" }  # Host(s) to deploy to
set(:deploy_to) { "/var/www/avalon" }  # Directory to deploy into
set(:user) { 'avalon' }                # User to deploy as
set(:branch) { "release/1.0.0" }       # Git branch to deploy
set :hls_dir, "/var/avalon/hls_streams"
ssh_options[:keys] = ["/opt/staging/avalon/vov_deployment_key"]

set :bundle_without, [:production]

role :web, deployment_host
role :app, deployment_host
role :db, deployment_host, :primary => true

before "bundle:install", "deploy:link_local_gemfile"
before "deploy:finalize_update", "deploy:remove_symlink_targets"
after "deploy:update_code", "deploy:symlink_dirs"
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

namespace :deploy do
	task :remove_symlink_targets do
		shared_children.each do |target|
			t = File.join(latest_release,target)
			run "if [ -f #{t} ]; then rm #{t}; fi"
		end
	end

  task :symlink_dirs do
    run "cd #{current_release}; ln -s #{hls_dir} #{latest_release}/public/streams"
  end

  task :migrate do
    run "cd #{current_release}; bundle exec rake RAILS_ENV=development db:migrate"    
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

