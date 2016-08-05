# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

namespace :delayed_job do 
  require 'daemons'
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
  task :reload => :environment do
    Delayed::Command.new(["reload"]).daemonize
  end

  desc "Returns Avalon's delayed_job worker status"
  task :status => :environment do
    Delayed::Command.new(["status"]).daemonize
  end
end
