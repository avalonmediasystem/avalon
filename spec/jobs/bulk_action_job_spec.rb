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

require 'rails_helper'

describe BulkActionJobs::IntercomPush do
  describe "perform" do
    let(:mo) { FactoryBot.create(:media_object) }
    let(:documents) { [mo.id] }
    let(:params) { { collection_id: "col_id", include_structure: 'true' } }
    let(:intercom) { double(Avalon::Intercom) }

    before do
      allow(Avalon::Intercom).to receive(:new).with(0).and_return(intercom)
    end

    it 'calls Intercom push' do
      expect(intercom).to receive(:push_media_object).with(mo, "col_id", true).and_return({ link: "http://new" })
      successes, errors = described_class.perform_now(documents, 0, params)
      expect(successes).not_to be_empty
      expect(errors).to be_empty
    end

    context "with error" do
      it "returns errors if got a status and no link" do
        check_push({ link: nil, status: "a status" })
      end

      it "returns errors if got no status and no link" do
        check_push({ link: nil, status: nil })
      end

      def check_push(result)
        allow(intercom).to receive(:push_media_object).with(mo, "col_id", true).and_return(result)
        successes, errors = described_class.perform_now(documents, 0, params)
        expect(successes).to be_empty
        expect(errors).not_to be_empty
      end
    end
  end
end

describe BulkActionJobs::Merge do
  let(:target) { FactoryBot.create(:media_object) }
  let(:subjects) { [] }

  before do
    2.times { subjects << FactoryBot.create(:media_object, :with_master_file) }
    allow(MediaObject).to receive(:find).and_call_original
    allow(MediaObject).to receive(:find).with(target.id).and_return(target)
  end

  describe "perform" do
    it 'calls MediaObject #merge' do
      expect(target).to receive(:merge!).with(subjects)
      BulkActionJobs::Merge.perform_now target.id, subjects.collect(&:id)
    end
  end
end

describe BulkActionJobs::ApplyCollectionAccessControl do
  let(:mo) { FactoryBot.create(:media_object) }
  let(:co) { mo.collection }

  describe "perform" do
    before do
      co.default_read_users = ["co_user"]
      co.default_read_groups = ["co_group"]
      co.default_hidden = true
      co.default_visibility = 'public'
      co.default_lending_period = 129600
      co.save!

      mo.read_users = ["mo_user"]
      mo.read_groups = ["mo_group"]
      mo.hidden = false
      mo.visibility = 'restricted'
      mo.lending_period = 1209600
      mo.save!
    end

    it "changes item discovery and access" do
      BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, true
      mo.reload
      expect(mo.hidden?).to be_truthy
      expect(mo.visibility).to eq('public')
    end

    it "changes item lending period" do
      BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, true
      mo.reload
      expect(mo.lending_period).to eq(co.default_lending_period)
    end

    context "overwrite is true" do
      it "replaces existing Special Access" do
        BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, true
        mo.reload
        expect(mo.read_users).to contain_exactly("co_user")
        expect(mo.read_groups).to contain_exactly("co_group", "public")
      end
    end

    context "overwrite is false" do
      it "adds to existing Special Access" do
        BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, false
        mo.reload
        expect(mo.read_users).to contain_exactly("mo_user", "co_user")
        expect(mo.read_groups).to contain_exactly("mo_group", "co_group", "public")
      end
    end
  end
end
