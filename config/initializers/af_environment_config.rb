class EnvironmentConfigurator < ActiveFedora::FileConfigurator
  def initialize
    reset!
  end

  def load_fedora_config
    return @fedora_config unless @fedora_config.empty?

    if ENV['FEDORA_URL'].present?
      ActiveFedora::Base.logger.info("ActiveFedora: loading fedora config from FEDORA_URL") if ActiveFedora::Base.logger
      fedora_url = URI.parse(ENV['FEDORA_URL'])
      @fedora_config = { user: fedora_url.user, password: fedora_url.password }
      fedora_url.userinfo = ''
      @fedora_config[:url] = fedora_url.to_s
    else
      super
    end
    @fedora_config
  end

  def load_solr_config
    return @solr_config unless @solr_config.empty?

    if ENV['SOLR_URL'].present?
      ActiveFedora::Base.logger.info("ActiveFedora: loading solr config from SOLR_URL") if ActiveFedora::Base.logger
      @solr_config = { url: ENV['SOLR_URL'] }
    else
      super
    end
    Blacklight.connection_config.merge!(@solr_config)
    @solr_config
  end
end
ActiveFedora.configurator = EnvironmentConfigurator.new
ActiveFedora.init
