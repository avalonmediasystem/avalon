# Example: 
# DB=postgres REPO=git@github.com:user/avalon.git BRANCH=deploy/prod USER=deploy APP_HOST=avalon.example.edu cap dynamic deploy

set :bundle_flags,  "--with #{ENV['DB']}" if ENV['DB']
set :bundle_without, 'development test debug'
set :rails_env, ENV['RAILS_ENV'] || 'production'
set :repo_url, ENV['REPO']
set :branch, ENV['BRANCH']
set :user, ENV['USER']
role :web, ENV['APP_HOST']
role :app, ENV['APP_HOST']
role :resque_worker, ENV['RESQUE_HOST'] || ENV['APP_HOST']
role :resque_scheduler, ENV['RESQUE_HOST'] || ENV['APP_HOST']
