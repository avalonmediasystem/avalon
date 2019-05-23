ActiveFedora::FileConfigurator.class_eval do
  def load_solr_config
     return @solr_config unless @solr_config.empty?
     @solr_config_path = config_path(:solr)

     ActiveFedora::Base.logger.info "ActiveFedora: loading solr config from #{::File.expand_path(@solr_config_path)}"
     begin
       config_erb = ERB.new(IO.read(@solr_config_path)).result(binding)
     rescue StandardError
       raise("solr.yml was found, but could not be parsed with ERB. \n#{$ERROR_INFO.inspect}")
     end

     begin
       solr_yml = YAML.safe_load(config_erb, [], [], true) # allow YAML aliases
     rescue StandardError
       raise("solr.yml was found, but could not be parsed.\n")
     end

     config = solr_yml.symbolize_keys
     raise "The #{ActiveFedora.environment.to_sym} environment settings were not found in the solr.yml config.  If you already have a solr.yml file defined, make sure it defines settings for the #{ActiveFedora.environment.to_sym} environment" unless config[ActiveFedora.environment.to_sym]
     config = config[ActiveFedora.environment.to_sym].symbolize_keys
     @solr_config = { url: solr_url(config) }.merge(config.slice(:update_path, :select_path, :read_timeout, :open_timeout))
   end
end

# Reset the solr config
ActiveFedora.configurator = ActiveFedora::FileConfigurator.new
