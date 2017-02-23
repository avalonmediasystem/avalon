if File.exists?(File.join(Rails.root, 'tmp', 'profiler.txt'))
  require 'rack-mini-profiler'
  require 'stackprof'
  require 'flamegraph'
  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rails.application.config.to_prepare do
    methods = File.read(File.join(Rails.root, 'tmp', 'profiler.txt')).split(/\n/)
    methods.each do |m|
      controller, method = m.strip.split(/#/)
      ::Rack::MiniProfiler.profile_method(controller.safe_constantize, method.to_sym) { |a| m } unless controller.nil?
    end
  end
end
