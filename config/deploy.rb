set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'
require 'rvm/capistrano'
require 'whenever/capistrano'

set :application, "avalon"
set :repository,  "git://github.com/avalonmediasystem/avalon.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :deploy_to, "/srv/rails/hydrant-test"
set :user, "vov"
set :use_sudo, false

#set :rvm_type, :root
set :rvm_ruby_string, 'ruby-1.9.3@avalon'                     # Or:
#set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"") # Read from local system

task :uname do
  run "uname -a"
end

require 'capistrano-unicorn'
