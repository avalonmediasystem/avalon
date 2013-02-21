unless Rails.env.test?
  Hydrant::Application.config.action_mailer.smtp_settings = Hydrant::Configuration['email']['mailer']['smtp']
end