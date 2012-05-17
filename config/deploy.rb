set :application, "hydrant"
set :repository,  "git://github.com/variations-on-video/hydrant.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "pawpaw.dlib.indiana.edu"                          # Your HTTP server, Apache/etc
role :app, "pawpaw.dlib.indiana.edu"                          # This may be the same as your `Web` server
role :db,  "pawpaw.dlib.indiana.edu", :primary => true # This is where Rails migrations will run

set :deploy_to, "/srv/rails/hydrant-test"
set :user, "vov"
set :use_sudo, false

set :rvm_ruby_string, 'ruby-1.9.3@hydrant'                     # Or:
#set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"") # Read from local system

require "rvm/capistrano" 

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
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end
