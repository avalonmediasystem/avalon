class ApplicationMailer < ActionMailer::Base
  default from: Avalon::Configuration.lookup('email.notification')
  layout 'mailer'
end
