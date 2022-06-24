# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

require "rails_helper"

RSpec.describe BatchRegistriesMailer, type: :mailer do
  describe 'batch_ingest_validation_error' do
    let(:manager) { FactoryBot.create(:manager, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com') }
    let(:collection) { FactoryBot.create(:collection, managers: [manager.user_key]) }
    let(:manifest_file) { File.new('spec/fixtures/dropbox/example_batch_ingest/batch_manifest.xlsx') }
    let(:package) { Avalon::Batch::Package.new(manifest_file, collection) }
    let(:errors) {['Michigan','Indiana','Illinios']}
    let(:notification_email_address) { Settings.email.notification }

    it "sends to the user when package has a registered user's email" do
       email = BatchRegistriesMailer.batch_ingest_validation_error(package, errors)
       expect(email.to).to include(manager.email)
       expect(email.subject).to include package.title
       expect(email).to have_body_text(package.title)
       expect(email).to have_body_text(collection.id)
       errors.each do |error|
         expect(email).to have_body_text(error)
       end
    end

    it "sends to notification email address if manifest's email does not belong to a registered user" do
       allow(package).to receive(:user).and_return(nil)
       email = BatchRegistriesMailer.batch_ingest_validation_error(package, errors)
       expect(email.to).to include(notification_email_address)
    end
  end

  describe 'batch_ingest_validation_success' do
    let(:manager) { FactoryBot.create(:manager, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com') }
    let(:collection) { FactoryBot.build(:collection, managers: [manager.user_key]) }
    let(:manifest_file) { File.new('spec/fixtures/dropbox/example_batch_ingest/batch_manifest.xlsx') }
    let(:package) { Avalon::Batch::Package.new(manifest_file, collection) }
    let(:errors) {['Michigan','Indiana','Illinios']}
    let(:notification_email_address) { Settings.email.notification }

    it "sends an email when a batch is successfully registered" do
       email = BatchRegistriesMailer.batch_ingest_validation_success(package)
       expect(email.to).to include(manager.email)
       expect(email.subject).to include package.title
       expect(email).to have_body_text(package.title)
    end
  end

  describe 'batch_registration_finished_mailer' do
    let(:batch_registries) { FactoryBot.create(:batch_registries, user_id: manager.id, collection: collection.id) }
    let(:manager) { FactoryBot.create(:manager, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com') }
    let(:collection) { FactoryBot.create(:collection) }
    let!(:batch_entries) { FactoryBot.create(:batch_entries, batch_registries: batch_registries, media_object_pid: media_object.id, complete: true) }
    let(:media_object) { FactoryBot.create(:media_object, collection: collection, permalink: "http://localhost:3000/media_objects/kfd39dnw") }

    it "sends an email when a batch finishes processing" do
       email = BatchRegistriesMailer.batch_registration_finished_mailer(batch_registries)
       expect(email.to).to include(manager.email)
       expect(email.subject).to include batch_registries.file_name
       expect(email.subject).to include collection.name
       expect(email).to have_body_text(batch_registries.file_name)
       expect(email).to have_body_text("<a href=\"#{media_object.permalink}\">")
       expect(email).to have_body_text(media_object.id)
    end

    it 'indicates when media objects have been deleted already' do
      deleted_media_object = FactoryBot.create(:media_object).destroy
      FactoryBot.create(:batch_entries, batch_registries: batch_registries, media_object_pid: deleted_media_object.id, complete: true)
      email = BatchRegistriesMailer.batch_registration_finished_mailer(batch_registries)
      expect(email.to).to include(manager.email)
      expect(email.subject).to include batch_registries.file_name
      expect(email.subject).to include collection.name
      expect(email).to have_body_text(batch_registries.file_name)
      expect(email).to have_body_text("<a href=\"#{media_object.permalink}\">")
      expect(email).to have_body_text(media_object.id)
      expect(email).to have_body_text("Item (#{deleted_media_object.id}) was created but no longer exists")
    end

    it 'works when the collection has been deleted already' do
      collection.destroy
      email = BatchRegistriesMailer.batch_registration_finished_mailer(batch_registries)
      expect(email.to).to include(manager.email)
      expect(email.subject).to include batch_registries.file_name
      expect(email).to have_body_text(batch_registries.file_name)
      expect(email).to have_body_text("<a href=\"#{media_object.permalink}\">")
      expect(email).to have_body_text(media_object.id)
    end
  end

  describe 'batch_encoding_finished' do
    let(:batch_registries) { FactoryBot.create(:batch_registries, user_id: manager.id, collection: collection.id) }
    let(:manager) { FactoryBot.create(:manager, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com') }
    let(:collection) { FactoryBot.create(:collection) }
    let!(:batch_entries) { FactoryBot.create(:batch_entries, batch_registries: batch_registries, media_object_pid: media_object.id, complete: true) }
    let(:media_object) { FactoryBot.create(:media_object, collection: collection, permalink: "http://localhost:3000/media_objects/kfd39dnw") }

    it "correctly sets up the email indicating that encoding is successful" do
      allow_any_instance_of(BatchEntries).to receive(:encoding_success?).and_return(true)
      allow_any_instance_of(BatchEntries).to receive(:encoding_error?).and_return(false)
      email = BatchRegistriesMailer.batch_encoding_finished(batch_registries)
      expect(email.to).to include(manager.email)
      expect(email.subject).to include batch_registries.file_name
      expect(email.subject).to include collection.name

      expect(email.subject).to include 'Success'

      expect(email).to have_body_text(batch_registries.file_name)
      expect(email).to have_body_text("<a href=\"#{media_object.permalink}\">")
      expect(email).to have_body_text(media_object.id)
    end

    it "correctly sets up the email indicating that encoding has errors" do
      allow_any_instance_of(BatchEntries).to receive(:encoding_success?).and_return(false)
      allow_any_instance_of(BatchEntries).to receive(:encoding_error?).and_return(true)
      email = BatchRegistriesMailer.batch_encoding_finished(batch_registries)
      expect(email.to).to include(manager.email)
      expect(email.subject).to include batch_registries.file_name
      expect(email.subject).to include collection.name

      expect(email.subject).to include 'Errors Present'

      expect(email).to have_body_text(batch_registries.file_name)
      expect(email).to have_body_text("<a href=\"#{media_object.permalink}\">")
      expect(email).to have_body_text(media_object.id)
    end
  end

  describe 'batch_registration_stalled_mailer' do
    let(:batch_registries) { FactoryBot.create(:batch_registries, collection: collection.id) }
    let(:notification_email_address) { Settings.email.notification }
    let(:collection) { FactoryBot.create(:collection) }

    it "sends an email when a batch has stalled" do
       email = BatchRegistriesMailer.batch_registration_stalled_mailer(batch_registries)
       expect(email.to).to include(notification_email_address)
       expect(email.subject).to include batch_registries.file_name
       expect(email.subject).to include collection.name
       expect(email).to have_body_text(batch_registries.id.to_s)
    end

    it 'works when the collection has been deleted already' do
      collection.destroy
      email = BatchRegistriesMailer.batch_registration_stalled_mailer(batch_registries)
      expect(email.to).to include(notification_email_address)
      expect(email.subject).to include batch_registries.file_name
      expect(email).to have_body_text(batch_registries.id.to_s)
    end
  end
end
