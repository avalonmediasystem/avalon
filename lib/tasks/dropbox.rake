require 'bundler/setup'
require 'guard'
require 'daemons'

def application_opts
  opts = {
    app_name: 'hydrant-dropbox',
    mode: :proc,
    dir_mode: :normal,
    dir: File.expand_path(File.join(Rails.root,'tmp/pids')),
    log_dir: File.expand_path(File.join(Rails.root,'log')), 
    log_output: true,
    multiple: false,
    proc: lambda {
      Dir.chdir(Rails.root) {
        Guard.start(
          :guardfile => 'Guardfile', 
          :group => ['dropbox'], 
          :watchdir => File.expand_path('..', Hydrant::Configuration['dropbox']['path']),
          :no_interactions => true
        )
      }
    }
  }
end

namespace :hydrant do
  namespace :dropbox do
    desc "Start the dropbox"
    task :start => :environment do
      opts = application_opts
      group = Daemons::ApplicationGroup.new(opts[:app_name],opts)
      app = group.new_application(opts)
      app.start
    end

    task :status => :environment do
      opts = application_opts
      group = Daemons::ApplicationGroup.new(opts[:app_name],opts)
      apps = group.find_applications_by_pidfiles(opts[:dir])
      if apps.length == 0
        $stderr.puts "#{group.app_name} is not running"
      else
        apps.each do |app|
          if app.running?
            $stderr.puts "#{group.app_name} [#{app.pid.pid}] is running"
          else
            $stderr.puts "#{group.app_name} [#{app.pid.pid}] is not running but pidfile exists"
          end
        end
      end
    end

    task :stop => :environment do
      opts = application_opts
      group = Daemons::ApplicationGroup.new(opts[:app_name],opts)
      apps = group.find_applications_by_pidfiles(opts[:dir])
      apps.each &:stop
    end
  end
end

