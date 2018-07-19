# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

require 'rails_helper'

describe IngestBatchStatusEmailJobs do
  describe IngestBatchStatusEmailJobs::IngestFinished do
    let(:batch_registry) { FactoryGirl.create(:batch_registries, user_id: manager.id) }
    let(:manager) { FactoryGirl.create(:manager, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com') }
    let(:batch_mailer) { double }

    before do
      allow(batch_mailer).to receive(:deliver_now)
    end

    it 'sends an email when the batch is complete with errors' do
      FactoryGirl.create(:batch_entries, batch_registries: batch_registry, error: true)
      expect(BatchRegistriesMailer).to receive(:batch_registration_finished_mailer).once.with(batch_registry).and_return(batch_mailer)
      described_class.perform_now
      expect(batch_registry.reload.error_email_sent).to be true
      expect(batch_registry.reload.error).to be true
      expect(batch_registry.reload.completed_email_sent).to be false
      expect(batch_registry.reload.complete).to be false
    end

    it 'sends an email when the batch is complete with no errors' do
      expect(BatchRegistriesMailer).to receive(:batch_registration_finished_mailer).once.with(batch_registry).and_return(batch_mailer)
      described_class.perform_now
      expect(batch_registry.reload.completed_email_sent).to be true
      expect(batch_registry.reload.complete).to be true
      expect(batch_registry.reload.error_email_sent).to be false
      expect(batch_registry.reload.error).to be false
    end

    it 'does not send an email when the batch is incomplete' do
      FactoryGirl.create(:batch_entries, batch_registries: batch_registry, complete: false)
      expect(BatchRegistriesMailer).not_to receive(:batch_registration_finished_mailer)
      described_class.perform_now
      expect(batch_registry.reload.error_email_sent).to be false
      expect(batch_registry.reload.error).to be false
      expect(batch_registry.reload.completed_email_sent).to be false
      expect(batch_registry.reload.complete).to be false
    end

    context 'with locked batch' do
      let(:batch_registry) { FactoryGirl.create(:batch_registries, user_id: manager.id, locked: true) }

      it 'does not send an email when the batch is locked' do
        expect(BatchRegistriesMailer).not_to receive(:batch_registration_finished_mailer)
        described_class.perform_now
        expect(batch_registry.reload.error_email_sent).to be false
        expect(batch_registry.reload.error).to be false
        expect(batch_registry.reload.completed_email_sent).to be false
        expect(batch_registry.reload.complete).to be false
      end
    end
  end
end
