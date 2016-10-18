require 'whenever/capistrano'

set :application, "avalon"
set :scm, :git
set :repository,  "git://github.com/avalonmediasystem/avalon.git"
set :rails_env, ENV['RAILS_ENV'] || "development"

set(:deployment_host) { "spruce.dlib.indiana.edu" }  # Host(s) to deploy to
set(:deploy_to) { "/var/www/avalon" }  # Directory to deploy into
set(:user) { 'avalon' }                # User to deploy as
set :branch, ENV['SCM_BRANCH'] || "develop"       # Git branch to deploy

set :hls_dir, "/var/avalon/hls_streams"
ssh_options[:keys] = ["/opt/staging/avalon/vov_deployment_key"] if ENV['CI_DEPLOY']

set :bundle_without, rails_env == "development" ? "production" : "development debug"
set(:whenever_command) { "RAILS_ENV=#{rails_env} bundle exec whenever" }

role :web, deployment_host
role :app, deployment_host
role :db, deployment_host, :primary => true

before "deploy:bundle_install", "deploy:link_local_files"
before "deploy:finalize_update", "deploy:remove_symlink_targets"
after "deploy:update_code", "deploy:symlink_dirs"
after "deploy:update_code", "deploy:migrate"
before "deploy:migrate", "deploy:bundle_install"
#after "deploy:create_symlink", "deploy:trust_rvmrc"
if ENV['AVALON_REINDEX']
  after "deploy:create_symlink", "deploy:reindex_everything"
end

set(:shared_children) {
  %{
    config/authentication.yml
    config/avalon.yml
    config/blacklight.yml
    config/browse_everything_providers.yml
    config/controlled_vocabulary.yml
    config/database.yml
    config/environments/development.rb
    config/fedora.yml
    config/lti.yml
    config/matterhorn.yml
    config/minter_state.yml
    config/role_map_#{fetch(:rails_env)}.yml
    config/secrets.yml
    config/solr.yml
    config/variations_media_object_id_map.yml
    Gemfile.local
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
    run "cd #{current_release}; bundle exec rake RAILS_ENV=#{rails_env} db:migrate"
  end

  task :bundle_install do
    run "cd #{current_release}; bundle install"
  end

  task :link_local_files do
    link_shared_file "user_auth_cas.rb", "config/initializers/user_auth_cas.rb"
    link_shared_file "iu-ldap.rb", "config/initializers/iu-ldap.rb"
    link_shared_file "permalink.rb", "config/initializers/permalink.rb"
  end

  task :trust_rvmrc do
    run "/usr/local/rvm/bin/rvm rvmrc trust #{latest_release}"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :reindex_everything do
    run "cd #{current_release} && RAILS_ENV=#{rails_env} bundle exec rake avalon:reindex"
  end
end

def link_shared_file source, target
    run "if [ -f #{shared_path}/#{source} ]; then ln -s #{shared_path}/#{source} #{latest_release}/#{target}; fi"
end
