
# config/initializers/recaptcha.rb
if Settings.recaptcha.present?
  Recaptcha.configure do |config|
    config.site_key = Settings.recaptcha.site_key
    config.secret_key = Settings.recaptcha.secret_key
  end
end
