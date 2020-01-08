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
set :yarn_flags, "--#{ENV['RAILS_ENV']}"
server ENV['APP_HOST'], roles: %w{web app db}, user: ENV['USER'] || 'avalon'
append :linked_files, ENV['LINKED_FILES'] if ENV['LINKED_FILES'] 

set :workers, { "*" => 2 }
