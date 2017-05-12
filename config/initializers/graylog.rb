if Settings.log_management.present? and Settings.log_management.provider == :graylog
  Rails.application.config.lograge.formatter = Lograge::Formatters::Graylog2.new
  Rails.logger = GELF::Logger.new(Settings.log_management.host, Settings.log_management.port, "WAN", { :protocol => GELF::Protocol::TCP })
end
