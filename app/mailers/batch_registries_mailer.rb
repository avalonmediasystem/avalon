# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

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
    @processed_items = BatchEntries.where(batch_registries_id: @batch_registry.id, complete: true).order(position: :asc)
    @supplemental_file_errors = @processed_items.select { |be| be.error == true }.compact
    @error_items = BatchEntries.where(batch_registries_id: @batch_registry.id, error: true).order(position: :asc)
    @error_items = @error_items - @supplemental_file_errors if !@supplemental_file_errors.empty?
    @completed_items = @processed_items.select { |be| be.error == false }.compact
    prefix = "Success:"
    prefix = "Errors Present:" unless (@error_items.empty? && @supplemental_file_errors.empty?)
    collection_text = Admin::Collection.find(@batch_registry.collection).name if Admin::Collection.exists?(@batch_registry.collection)
    collection_text ||= "Collection"

    mail(
      to: email,
      from: Settings.email.notification,
      subject: "#{prefix} Batch Registry #{@batch_registry.file_name} for #{collection_text} has completed"
    )
  end

  # Used to send an email when a batch appears to be stalled
  def batch_registration_stalled_mailer(batch_registry)
    @batch_registry = batch_registry
    email = Settings.email.notification
    collection_text = Admin::Collection.find(@batch_registry.collection).name if Admin::Collection.exists?(@batch_registry.collection)
    collection_text ||= "Collection"

    mail(
      to: email,
      from: Settings.email.notification,
      subject: "Batch Registry #{@batch_registry.file_name} for #{collection_text} has stalled"
    )
  end

  # Update the progress of finished (success or error) batch encoding
  def batch_encoding_finished(batch_registry)
    @batch_registry = batch_registry
    @user = User.find(@batch_registry.user_id)
    @email = @user.email unless @user.nil?
    @email ||= Settings.email.notification
    @collection_text = Admin::Collection.find(@batch_registry.collection).name if Admin::Collection.exists?(@batch_registry.collection)
    @collection_text ||= "Collection"

    @status = @batch_registry.encoding_success? ? "Success" : "Errors Present"

    mail(
      to: @email,
      from: Settings.email.notification,
      subject: "#{@status}: Batch Registry #{@batch_registry.file_name} for #{@collection_text} has finished encoding"
    )
  end

end
