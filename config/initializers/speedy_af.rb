Rails.application.config.to_prepare do
  SpeedyAF::Base.class_eval do
    def cache_key_with_version
      "#{model.to_s.underscore}/#{id}-#{_version_}"
    end
  end
end
