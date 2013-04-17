require 'bundler/setup'
require "rvm/capistrano"
require 'bundler/capistrano'
require 'whenever/capistrano'

set :stages, %W(avalon matterhorn)
set :default_stage, "avalon"
require 'capistrano/ext/multistage'

set(:whenever_command) { "bundle exec whenever" }
set(:bundle_flags) { "--quiet --path=#{deploy_to}/shared/gems" }
set :rvm_ruby_string, "1.9.3"
set :rvm_type, :system

set :scm, :git
set :keep_releases, 3

task :uname do
  run "uname -a"
end
