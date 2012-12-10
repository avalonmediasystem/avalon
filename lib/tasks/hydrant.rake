namespace :hydrant do
  namespace :services do
    services = ["jetty", "felix"]
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
  namespace :assets do 
   desc "Clears javascripts/cache and stylesheets/cache"
   task :clear => :environment do      
     FileUtils.rm(Dir['public/javascripts/cache/[^.]*'])
     FileUtils.rm(Dir['public/stylesheets/cache/[^.]*'])
   end
  end
  
  namespace :batch do 
    desc "Starts Hydrant batch ingest"
    task :ingest => :environment do
      require 'hydrant/batch_ingest'
      Hydrant::Batch.ingest
    end
  end
end
