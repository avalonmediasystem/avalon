# config valid only for current version of Capistrano
lock '>=3.6.1'

set :application, 'avalon'
set :repo_url, 'git://github.com/avalonmediasystem/avalon.git'

# If SCM_BRANCH is set, use it. Otherwise, ask for a branch, defaulting to the currently checked out branch.
set :branch, -> { ENV['SCM_BRANCH'] || ask(:branch, `git rev-parse --abbrev-ref HEAD`.chomp) }

append :linked_files, "Gemfile.local", "config/*.yml", "config/*/*.yml", "config/initializers/*.rb", "public/robots.txt"
append :linked_dirs, 'log', 'tmp'

set :conditionally_migrate, true
set :keep_assets, 2
set :migration_role, :app
set :migration_servers, -> { primary(fetch(:migration_role)) }
set :passenger_restart_with_touch, true
set :resque_environment_task, true

after "deploy:restart", "resque:restart"
after "deploy:restart", "resque:scheduler:restart"
