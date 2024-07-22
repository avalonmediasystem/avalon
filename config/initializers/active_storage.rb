# This is set in config/application.rb but it seems like the settings aren't loaded at that point so doing it again here
Rails.application.config.active_storage.service = (Settings&.active_storage&.service.presence || "local").to_sym
