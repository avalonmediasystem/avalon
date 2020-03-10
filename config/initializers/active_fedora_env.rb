class EnvironmentConfigurator < ActiveFedora::FileConfigurator
  def initialize
    reset!
  end

  def load_fedora_config
    return @fedora_config unless @fedora_config.empty?

    fedora_setting = Settings.fedora&.url || ENV['FEDORA_URL']
    fedora_timeout = Settings.fedora&.timeout || ENV['FEDORA_TIMEOUT']
    if fedora_setting.present?
      ActiveFedora::Base.logger.info("ActiveFedora: loading fedora config from FEDORA_URL") if ActiveFedora::Base.logger
      fedora_url = URI.parse(fedora_setting)
      @fedora_config = { user: fedora_url.user, password: fedora_url.password, base_path: ENV['FEDORA_BASE_PATH'] || "" }
      fedora_url.userinfo = ''
      @fedora_config[:url] = fedora_url.to_s
      @fedora_config[:request] = { timeout: Float(fedora_timeout), open_timeout: Float(fedora_timeout) } unless fedora_timeout.blank?
      ENV['FEDORA_URL'] ||= fedora_setting
    else
      super
    end
    @fedora_config
  end


  def load_solr_config
    return @solr_config unless @solr_config.empty?

    solr_setting = Settings.solr_url || ENV['SOLR_URL']
    if solr_setting.present?
      ActiveFedora::Base.logger.info("ActiveFedora: loading solr config from SOLR_URL") if ActiveFedora::Base.logger
      @solr_config = { url: solr_setting }
      ENV['SOLR_URL'] ||= solr_setting
    else
      super
    end
    Blacklight.connection_config.merge!(@solr_config)
    @solr_config
  end
end
ActiveFedora.configurator = EnvironmentConfigurator.new
ActiveFedora.init
