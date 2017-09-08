class BatchRegistriesMailer < ApplicationMailer
  def batch_ingest_validation_error( package, errors )
    @package = package
    @errors = errors
    email = package.user.email if package.user
    email ||= Avalon::Configuration.lookup('email.notification')
    mail(
      to: email,
      subject: "Failed batch ingest registration for: #{package.title}",
    )
  end

  def batch_ingest_validation_success( package )
    @package = package
    email = package.user.email
    mail(
      to: email,
      from: Avalon::Configuration.lookup('email.notification'),
      subject: "Successfully registered batch ingest: #{package.title}",
    )
  end
end
