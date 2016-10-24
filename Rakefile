# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

unless Rails.env.production?
  require 'solr_wrapper/rake_task'
end

task default: [:ci]

Rails.application.load_tasks

task :ci do
  run_server 'test' do
    Rake::Task['spec'].invoke
  end
end

namespace :server do
  desc 'Run Fedora and Solr for development environment'
  task :development do
    run_server 'development' do
      IO.popen('rails server') do |io|
        io.each do |line|
          puts line
        end
      end
    end
  end

  desc 'Run Fedora and Solr for test environment'
  task :test do
    run_server 'test' do
      sleep
    end
  end
end

def run_server(environment)
  with_server(environment) do
    puts " ***** #{environment} servers started"
    puts "\n^C to stop"
    begin
      yield
    rescue Interrupt
      puts 'Shutting down...'
    end
  end
end
