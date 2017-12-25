class ApplicationMailer < ActionMailer::Base
  default from: Settings.email.notification
  layout 'mailer'
end
