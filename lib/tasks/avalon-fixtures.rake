namespace :avalon do
  
  desc "Init Avalon configuration" 
  task :init => [:environment] do
    # We need to just start rails so that all the models are loaded
  end

  desc "Load avalon models"
  task :load_models do
    require "hydra-head"
		require File.expand_path(File.dirname(__FILE__) + '../../../config/environment')
  end

  namespace :fixtures do
    task :load do
			Rails.env = 'test'
      ENV["dir"] ||= File.join("spec", "fixtures")
      loader = ActiveFedora::FixtureLoader.new(ENV['dir'])
      Dir.glob("#{ENV['dir']}/*.foxml.xml").each do |fixture_path|
        pid = File.basename(fixture_path, ".foxml.xml").sub("_",":")
        begin
          foo = loader.reload(pid)
          puts "Updated #{pid}"
        rescue Errno::ECONNREFUSED => e
          puts "Can't connect to Fedora! Are you sure jetty is running?"
        rescue Exception => e
          puts("Received a Fedora error while loading #{pid}\n#{e}")
          logger.error("Received a Fedora error while loading #{pid}\n#{e}")
        end
      end
    end

    desc "Remove default Hydra fixtures"
    task :delete do
			Rails.env = 'test'
      ENV["dir"] ||= File.join("spec", "fixtures")
      loader = ActiveFedora::FixtureLoader.new(ENV['dir'])
      Dir.glob("#{ENV['dir']}/*.foxml.xml").each do |fixture_path|
        pid = File.basename(fixture_path, ".foxml.xml").sub("_",":")
        video = Video.find(pid)
				video.parts.each do |part|
					puts "Deleting #{part.pid}"
					ENV["pid"] = part.pid
				  Rake::Task["repo:delete"].reenable
          Rake::Task["repo:delete"].invoke
				end

   			ENV["pid"] = pid
        Rake::Task["repo:delete"].reenable
        Rake::Task["repo:delete"].invoke
      end
    end

    desc "Refresh default Avalon fixtures"
    task :refresh => [:load_models, :delete, :load]

  end
end
