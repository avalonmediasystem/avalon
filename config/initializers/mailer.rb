unless Rails.env.test?
  Avalon::Application.config.action_mailer.smtp_settings = Avalon::Configuration.lookup('email.mailer.smtp').symbolize_keys
  ActionMailer::Base.smtp_settings = Avalon::Application.config.action_mailer.smtp_settings
end
