if Settings.email.mailer.present? && Settings.email.mailer == :aws_sdk
  require 'aws-sdk-rails'
  Aws::Rails.add_action_mailer_delivery_method(:aws_sdk)
  ActionMailer::Base.delivery_method = :aws_sdk
end
