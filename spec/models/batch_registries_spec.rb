# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

describe BatchRegistries do
  subject { FactoryGirl.build(:batch_registries) }

  describe '#save' do
    it "persists an error when the user doesn't exist" do
      batch_registries = FactoryGirl.build(:batch_registries, user_id: 10000)
      batch_registries.save
      expect(batch_registries.error).to be true
      expect(batch_registries.error_message).to be_present
    end

    it 'persists' do
      subject.save
      subject.reload
      expect(subject.file_name).to be_present
      expect(subject.dir).to be_present
      expect(subject.user_id).to be_present
      expect(subject.collection).to be_present
      expect(subject.complete).not_to be_nil
      expect(subject.error).not_to be_nil
      expect(subject.error_email_sent).not_to be_nil
      expect(subject.processed_email_sent).not_to be_nil
      expect(subject.completed_email_sent).not_to be_nil
      expect(subject.locked).not_to be_nil
    end

    it { is_expected.to validate_presence_of(:collection) }
    it { is_expected.to validate_presence_of(:file_name) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  describe '#file_name=' do
    subject { BatchRegistries.new }

    it 'generates a replay name' do
      expect { subject.file_name = "file.mp4" }.to change { subject.replay_name }
      expect(subject.replay_name.ends_with?(subject.file_name)).to be true
    end

    it "doesn't overwrite the existing replay name" do
      subject.replay_name = "replay-name"
      expect { subject.file_name = "file.mp4" }.not_to change { subject.replay_name }
    end
  end
end
