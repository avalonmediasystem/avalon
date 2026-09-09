
# config/initializers/recaptcha.rb
if Admin::ApplicationSetting.instance.recaptcha.present?
  Recaptcha.configure do |config|
    config.site_key = Admin::ApplicationSetting.instance.recaptcha.site_key
    config.secret_key = Admin::ApplicationSetting.instance.recaptcha.secret_key
  end
end
