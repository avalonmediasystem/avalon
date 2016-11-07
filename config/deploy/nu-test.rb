set :bundle_flags,  '--with postgres'
set :bundle_without, 'test production'
set :rails_env, 'development'
server 'avalon-web-dev.library.northwestern.edu', roles: %w{web app resque_worker resque_scheduler}, user: 'deploy'
