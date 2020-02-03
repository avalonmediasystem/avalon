set :rails_env, ENV['RAILS_ENV'] || 'production'
set :bundle_flags,  "--with #{ENV['DB']}" if ENV['DB']
set :bundle_without, fetch(:rails_env) == "development" ? "production" : "development debug test sqlite"
set :repo_url, ENV['REPO'] || 'git@github.iu.edu:AvalonIU/Avalon.git'
set :branch, ENV['SCM_BRANCH'] || "mco-staging"
set :yarn_roles, :web
set :deploy_to, ENV['DEPLOY_TO'] || "/srv/avalon/avalon_r6"
server ENV['HOST'] || 'sodium.dlib.indiana.edu', roles: %w{web app worker}, user: ENV['DEPLOY_USER'] || 'avalon'
ssh_options[:keys] = ["/opt/staging/avalon/vov_deployment_key"] if ENV['CI_DEPLOY']
set :workers, { "*" => 2 }
