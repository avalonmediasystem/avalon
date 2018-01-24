class BatchRegistriesMailer < ApplicationMailer
  def batch_ingest_validation_error(package, errors)
    @package = package
    @errors = errors
    email = package.user.email if package.user
    email ||= Settings.email.notification
    mail(
      to: email,
      subject: "Failed batch ingest registration for: #{package.title}"
    )
  end

  def batch_ingest_validation_success(package)
    @package = package
    email = package.user.email
    mail(
      to: email,
      from: Settings.email.notification,
      subject: "Successfully registered batch ingest: #{package.title}"
    )
  end

  # Used to send an email when an entire batch is finished, all entries are in complete or error
  def batch_registration_finished_mailer(batch_registry)
    @batch_registry = batch_registry
    @user = User.find(@batch_registry.user_id)
    email = @user.email unless @user.nil?
    email ||= Settings.email.notification
    @error_items = BatchEntries.where(batch_registries_id: @batch_registry.id, error: true).order(position: :asc)
    @completed_items = BatchEntries.where(batch_registries_id: @batch_registry.id, complete: true).order(position: :asc)
    prefix = "Success:"
    prefix = "Errors Present:" unless @error_items.empty?

    mail(
      to: email,
      from: Settings.email.notification,
      subject: "#{prefix} Batch Registry #{@batch_registry.file_name} for #{Admin::Collection.find(@batch_registry.collection).name} has completed"
    )
  end

  # Used to send an email when a batch appears to be stalled
  def batch_registration_stalled_mailer(batch_registry)
    @batch_registry = batch_registry
    email = Settings.email.notification
    mail(
      to: email,
      from: Settings.email.notification,
      subject: "Batch Registry #{@batch_registry.file_name} for #{Admin::Collection.find(@batch_registry.collection).name} has stalled"
    )
  end
end
