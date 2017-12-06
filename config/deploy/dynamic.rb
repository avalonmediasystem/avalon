# Example:
# DB=postgres REPO=git@github.com:user/avalon.git BRANCH=deploy/prod USER=deploy APP_HOST=avalon.example.edu cap dynamic deploy

set :rails_env, ENV['RAILS_ENV'] || 'production'
set :bundle_flags,  "--with #{ENV['DB']}" if ENV['DB']
set :bundle_without, ENV['RAILS_ENV'] == "development" ? "production" : 'development test debug'
set :repo_url, ENV['REPO']
set :branch, ENV['BRANCH']
set :deploy_to, ENV['DEPLOY_TO']
set :hls_dir, ENV['HLS_DIR']
set :user, ENV['USER']
server ENV['APP_HOST'], roles: %w{web app db}, user: ENV['USER'] || 'avalon'
server ENV['RESQUE_HOST'] || ENV['APP_HOST'], roles: %w{resque_worker resque_scheduler}, user: ENV['RESQUE_USER'] || 'avalon'
append :linked_files, ENV['LINKED_FILES'] if ENV['LINKED_FILES'] 

set :workers, { "*" => 2 }
