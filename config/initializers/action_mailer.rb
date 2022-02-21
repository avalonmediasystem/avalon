ActionMailer::MailDeliveryJob.rescue_from(StandardError) do |exception|
  Rails.logger.error "Error delivering mail: #{exception}"
end

case Settings&.email&.mailer&.to_sym
when :aws_sdk
  require 'aws-sdk-rails'
  Aws::Rails.add_action_mailer_delivery_method(:aws_sdk)
  ActionMailer::Base.delivery_method = :aws_sdk
when :smtp
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = Settings.email.config.to_h
end
