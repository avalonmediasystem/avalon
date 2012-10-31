module Hydrant
  def self.config
    @config ||= begin
      raise "The #{::Rails.env} environment settings were not found in the hydrant.yml config" unless hydrant_yml[::Rails.env]
      hydrant_yml[::Rails.env].symbolize_keys
    end
  end

  def self.hydrant_yml
    require 'erb'
    require 'yaml'

    return @hydrant_yml if @hydrant_yml
    unless File.exists?(hydrant_file)
      raise "Unable to locate the configuration file for Hydrant. Make sure #{hydrant_file} is present and readable"
    end

    begin
      @hydrant_erb = ERB.new(IO.read(hydrant_file)).result(binding)
    rescue Exception => e
      raise "hydrant.yml was found but could not be processed\n#{$!.inspect}"
    end

    begin
      @hydrant_yml = YAML::load(@hydrant_erb)
    rescue StandardError => e
      raise "hydrant.yml was found but could not be parsed"
    end

    if @hydrant_yml.nil? or not @hydrant_yml.is_a?(Hash)
      raise "hydrant.yml was found but appears to be empty or improperly formatted"
    end
    @hydrant_yml
  end
end
