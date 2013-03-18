server "lancelot.dlib.indiana.edu", :app, :web, :db, :primary => true
server "mallorn.dlib.indiana.edu", :app, :web, :db, :primary => true

set :deploy_env, "development"
set :git_enable_submodules, true

set :dropbox_path, "/srv/avalon/dropbox"

#For capistrano to send the correct rails env to unicorn
set :unicorn_env, "staging"

set :branch, "develop"
set :branch, ENV['SCM_BRANCH'] if ENV['SCM_BRANCH']

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

namespace :deploy do
  task :update_code, :roles => :app do
    run "cd #{current_release}; git checkout Gemfile.lock; git checkout config/role_map_development.yml; git pull origin #{branch}"
  end

  task :update_submodules, :roles => :app do
    #Make sure that the services are stopped before doing this
    run "cd #{current_release}/felix; git clean -df .; git checkout HEAD ."
    run "cd #{current_release}/red5; git clean -df .; git checkout HEAD ."
    run "cd #{current_release}/jetty; git clean -df .; git checkout HEAD ."
    run "cd #{current_release}; git submodule update"
  end

  task :start, :roles => :app do
    run "cd #{current_release}; rake avalon:services:start"
  end

  task :stop, :roles => :app do
    run "cd #{current_release}; rake avalon:services:stop"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "cd #{current_release}; rake avalon:services:stop"
    run "cd #{current_release}; rake avalon:services:start"
  end

  task :quick_update, :roles => :app do
    run "cd #{current_release}; git checkout Gemfile.lock; git checkout config/role_map_development.yml; git pull origin master"    
  end

  namespace :jetty do
    task :config, :roles => :app do
      run "cd #{current_release}; rake jetty:config"
    end
    task :clear, :roles => :app do
      run "cd #{current_release}/jetty; git clean -df .; git checkout HEAD ."
    end
  end

  namespace :felix do
    task :clear, :roles => :app do
      run "cd #{current_release}/felix; git clean -df .; git checkout HEAD ."
    end
  end

  namespace :red5 do
    task :clear, :roles => :app do
      run "cd #{current_release}/red5; git clean -df .; git checkout HEAD ."
    end
  end

  namespace :bundle do
    task :install, :roles => :app do
      run "cd #{current_release}; QMAKE=/usr/bin/qmake-qt4 bundle install"
    end
  end

  namespace :db do
    task :setup, roles => :db do
      run "cd #{current_release}; rake RAILS_ENV=development db:migrate"
    end
  end

  namespace :delayed_job do
    desc "Start delayed_job workers"
    task :start, :roles => :app do
      run "cd #{current_release}; rake delayed_job:start "
    end

    desc "Stop delayed_job workers"
    task :stop, :roles => :app do
      run "cd #{current_release}; rake delayed_job:stop"
    end

    desc "Stop delayed_job workers"
    task :restart, :roles => :app do
      run "cd #{current_release}; rake delayed_job:restart"
    end
  end

  namespace :avalon do
    task :load_fixtures, :roles => :app do
      # This doesn't work
      #run "rm #{dropbox_path}/demo_fixtures/*.processed"
      # Suggested as a fix by Michael Klein
      run "find #{dropbox_path}/demo_fixtures -name '*.processed' -delete" 

      #XXX Do something fancy like get dropbox location from the server then scp or local fs copy the whole batch into place from source control
#      run "rails r \"p Avalon::Configuration['dropbox']['path']\"" do |channel, stream, data|
#        dropbox_path = data
#        return if dropbox_path.blank?
#        p "Dropbox path: #{dropbox_path}"
#
#        #Delete old fixtures batch directory from dropbox
#        run "rm -r #{dropbox_path}/demo_fixtures"
#        #Copy new fixtures batch directory to dropbox
#        run "cp -r #{current_release}/spec/fixtures/demo_fixtures #{dropbox_path}"
#      end
      end
    end
end

before("deploy:update_submodules", "deploy:stop")
after("deploy:update_code", "deploy:bundle:install")
after("deploy:update_code", "deploy:update_submodules")
after("deploy:update_code", "deploy:jetty:config")
after("deploy:update_code", "deploy:db:setup")
after('deploy:restart', 'unicorn:restart')
