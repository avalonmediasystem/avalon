unless Rails.env.test?
  Hydrant::Application.config.action_mailer.smtp_settings = {
    address: Hydrant::Configuration['email']['mailer']['smtp']['address'],
    port: Hydrant::Configuration['email']['mailer']['smtp']['port'],
    enable_starttls_auto: Hydrant::Configuration['email']['mailer']['smtp']['enable_starttls_auto']
  }
end