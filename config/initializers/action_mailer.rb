ActiveSupport.on_load(:action_mailer) do
  ActionMailer::MailDeliveryJob.rescue_from(StandardError) do |exception|
    Rails.logger.error "Error delivering mail: #{exception}"
  end

  case Settings&.email&.mailer&.to_sym
  when :aws_sdk
    require 'aws-sdk-rails'
    require 'aws-actionmailer-ses'

    ActionMailer::Base.delivery_method = :ses_v2
    ActionMailer::Base.ses_v2_settings = Settings.email.config.to_h
  when :smtp
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = Settings.email.config.to_h
  end
end
