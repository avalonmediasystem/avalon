server "lancelot.dlib.indiana.edu", :app, :web, :db, :primary => true

set :deploy_env, "development"

set :git_enable_submodules, true

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
  task :start, :roles => :app do
    run "cd #{current_release}; rake hydrant:services:start"
    run "cd #{current_release}; rails s -d"
  end

  task :stop, :roles => :app do
    run "cd #{current_release}; rake hydrant:services:stop"
    run "kill -9 `pgrep ruby`"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "cd #{current_release}; rake hydrant:services:stop"
    run "kill -9 `pgrep ruby`"
    run "cd #{current_release}; rake hydrant:services:start"
    run "cd #{current_release}; rails s -d"
  end

  namespace :jetty do
    task :config, :roles => :app do
      run "cd #{current_release}; rake jetty:config"
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
end


