namespace :hydrant do
  namespace :services do
    services = ["jetty", "felix", "red5"]
    desc "Start Hydrant's dependent services"
    task :start do
      services.map { |service| Rake::Task["#{service}:start"].invoke }
    end
    desc "Stop Hydrant's dependent services"
    task :stop do
      services.map { |service| Rake::Task["#{service}:stop"].invoke }
    end
    desc "Status of Hydrant's dependent services"
    task :status do
      services.map { |service| Rake::Task["#{service}:status"].invoke }
    end
    desc "Restart Hydrant's dependent services"
    task :restart do
      services.map { |service| Rake::Task["#{service}:restart"].invoke }
    end
   end  
end
