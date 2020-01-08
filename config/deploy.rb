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

# There is a known bug that prevents sidekiq from starting when pty is true on Capistrano 3.
set :pty,  false
set :sidekiq_config, -> { File.join(shared_path, 'config', 'sidekiq.yml') }
SSHKit.config.command_map[:sidekiq] = "bundle exec sidekiq"
