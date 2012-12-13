namespace :delayed_job do 
  require 'delayed/command'

  desc "Starts Hydrant's delayed_job worker"
  task :start => :environment do
    Delayed::Command.new(["-n", "2", "start"]).daemonize
  end

  desc "Stop Hydrant's delayed_job worker"
  task :stop => :environment do
    Delayed::Command.new(["stop"]).daemonize
  end

  desc "Restarts Hydrant's delayed_job worker"
  task :restart => :environment do
    Delayed::Command.new(["restart"]).daemonize
  end

  desc "Reloads Hydrant's delayed_job worker"
  task :restart => :environment do
    Delayed::Command.new(["reload"]).daemonize
  end

  desc "Returns Hydrant's delayed_job worker status"
  task :status => :environment do
    Delayed::Command.new(["status"]).daemonize
  end
end
