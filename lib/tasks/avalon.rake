# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

namespace :avalon do
  namespace :services do
    services = ["jetty", "felix", "delayed_job"]
    desc "Start Avalon's dependent services"
    task :start do
      services.map { |service| Rake::Task["#{service}:start"].invoke }
    end
    desc "Stop Avalon's dependent services"
    task :stop do
      services.map { |service| Rake::Task["#{service}:stop"].invoke }
    end
    desc "Status of Avalon's dependent services"
    task :status do
      services.map { |service| Rake::Task["#{service}:status"].invoke }
    end
    desc "Restart Avalon's dependent services"
    task :restart do
      services.map { |service| Rake::Task["#{service}:restart"].invoke }
    end
   end  
  namespace :assets do 
   desc "Clears javascripts/cache and stylesheets/cache"
   task :clear => :environment do      
     FileUtils.rm(Dir['public/javascripts/cache/[^.]*'])
     FileUtils.rm(Dir['public/stylesheets/cache/[^.]*'])
   end
  end
  namespace :batch do 
    desc "Starts Avalon batch ingest"
    task :ingest => :environment do
      # Starts the ingest process
      require 'avalon/batch_ingest'
      Avalon::Batch.ingest
    end
  end  
  namespace :user do
    desc "Create user (assumes identity authentication)"
    task :create => :environment do
      if ENV['avalon_username'].nil? or ENV['avalon_password'].nil?
        abort "You must specify a username and password.  Example: rake avalon:user:create avalon_username=user@example.edu avalon_password=password avalon_groups=group1,group2"
      end

      require 'role_controls'
      username = ENV['avalon_username'].dup
      password = ENV['avalon_password']
      groups = ENV['avalon_groups'].split(",")
     
      Identity.create(email: username, password: password)
      User.create(username: username)
      groups.each do |group|
	RoleControls.add_role(group) unless RoleControls.role_exists? group
        RoleControls.add_user_role(username, group)
      end

      puts "User #{username} created and added to groups #{groups}"
    end
    desc "Delete user"
    task :delete => :environment do
      if ENV['avalon_username'].nil?
        abort "You must specify a username  Example: rake avalon:user:delete avalon_username=user@example.edu"
      end

      require 'role_controls'
      username = ENV['avalon_username'].dup
      groups = RoleControls.user_roles username

      Identity.where(email: username).destroy_all
      User.where(username: username).destroy_all
      groups.each do |group|
        RoleControls.remove_user_role(username, group)
      end

      puts "Deleted user #{username} and removed them from groups #{groups}"
    end
    desc "Change password (assumes identity authentication)"
    task :passwd => :environment do  
      if ENV['avalon_username'].nil? or ENV['avalon_password'].nil?
        abort "You must specify a username and password.  Example: rake avalon:user:passwd avalon_username=user@example.edu avalon_password=password"
      end

      username = ENV['avalon_username'].dup
      password = ENV['avalon_password']
      Identity.where(email: username).each {|identity| identity.password = password; identity.save}

      puts "Updated password for user #{username}"
    end
  end
end
