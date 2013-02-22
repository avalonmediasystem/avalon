namespace :delayed_job do 
  require 'delayed/command'

  desc "Starts Avalon's delayed_job worker"
  task :start => :environment do
    Delayed::Command.new(["-n", "2", "start"]).daemonize
  end

  desc "Stop Avalon's delayed_job worker"
  task :stop => :environment do
    Delayed::Command.new(["stop"]).daemonize
  end

  desc "Restarts Avalon's delayed_job worker"
  task :restart => :environment do
    Delayed::Command.new(["restart"]).daemonize
  end

  desc "Reloads Avalon's delayed_job worker"
  task :restart => :environment do
    Delayed::Command.new(["reload"]).daemonize
  end

  desc "Returns Avalon's delayed_job worker status"
  task :status => :environment do
    Delayed::Command.new(["status"]).daemonize
  end
end
