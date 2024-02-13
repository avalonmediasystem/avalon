# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe IngestBatchEntryJob do
  let(:collection) { FactoryBot.create(:collection) }
  let(:batch_registry) { FactoryBot.create(:batch_registries, collection: collection.id) }
  let(:batch_entry) { FactoryBot.create(:batch_entries, batch_registries: batch_registry) }

  describe "perform" do
    it 'runs' do
      expect { described_class.perform_now(batch_entry) }.to change { MediaObject.count }.by(1)
    end

    context 'when media object exists and is published' do
      let(:published_media_object) { FactoryBot.build(:published_media_object) }

      before do
        allow(MediaObject).to receive(:exists?).with(batch_entry.media_object_pid).and_return(true)
        allow(MediaObject).to receive(:find).with(batch_entry.media_object_pid).and_return(published_media_object)
      end

      it 'sets an error state' do
        expect { described_class.perform_now(batch_entry) }.to change { batch_entry.error }.from(false).to(true)
      end
    end
  end
end
