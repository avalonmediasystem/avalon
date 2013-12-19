unless Rails.env.test?
  Avalon::Application.config.action_mailer.smtp_settings = Avalon::Configuration.lookup('email.mailer.smtp')
end