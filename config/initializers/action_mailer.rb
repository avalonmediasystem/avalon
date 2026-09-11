# TODO: Make sure that this works for regular application boot with a fresh database
ActiveSupport.on_load(:action_mailer) do
  ActionMailer::MailDeliveryJob.rescue_from(StandardError) do |exception|
    Rails.logger.error "Error delivering mail: #{exception}"
  end

  if Rails.env.test?
    ActionMailer::Base.delivery_method = :test
  else
    case Admin::ApplicationSetting.instance&.email&.mailer&.to_sym
    when :aws_sdk
      require 'aws-sdk-rails'
      require 'aws-actionmailer-ses'

      ActionMailer::Base.delivery_method = :ses_v2
      ActionMailer::Base.ses_v2_settings = Admin::ApplicationSetting.instance.email.config.to_h
    when :smtp
      ActionMailer::Base.delivery_method = :smtp
      ActionMailer::Base.smtp_settings = Admin::ApplicationSetting.instance.email.config.to_h
    end
  end
end
