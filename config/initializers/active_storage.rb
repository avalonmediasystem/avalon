# This is set in config/application.rb but it seems like the settings aren't loaded at that point so doing it again here
Rails.application.config.active_storage.service = (Settings&.active_storage&.service.presence || "local").to_sym

Rails.application.config.to_prepare do
  # Override ActiveStorage behavior to allow inline disposition for all file types
  # See https://github.com/avalonmediasystem/avalon/issues/6399
  # and https://github.com/rails/rails/blob/v8.0.4/activestorage/app/models/active_storage/blob/servable.rb
  ActiveStorage::Blob::Servable.module_eval do
    def forcibly_serve_as_binary?
      #ActiveStorage.content_types_to_serve_as_binary.include?(content_type)
      false
    end

    def allowed_inline?
      #ActiveStorage.content_types_allowed_inline.include?(content_type)
      true
    end
  end
end
