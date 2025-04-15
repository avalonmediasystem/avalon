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

    it "changes only item discovery" do
      BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, true, 'discovery'
      mo.reload
      expect(mo.hidden?).to be_truthy
      expect(mo.read_users).to contain_exactly('mo_user')
      expect(mo.read_groups).to contain_exactly('mo_group', 'registered')
      expect(mo.visibility).to eq('restricted')
      expect(mo.lending_period).to eq(1209600)
    end

    it 'changes item visibility and read group' do
      BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, true, 'visibility'
      mo.reload
      expect(mo.visibility).to eq('public')
      expect(mo.read_users).to contain_exactly('mo_user')
      expect(mo.read_groups).to contain_exactly('mo_group', 'public')
      expect(mo.hidden?).to be_falsey
      expect(mo.lending_period).to eq(1209600)
    end

    context "with cdl enabled" do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
      before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }
      it "changes only item lending period" do
        BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, true, 'lending_period'
        mo.reload
        expect(mo.lending_period).to eq(co.default_lending_period)
        expect(mo.hidden?).to be_falsey
        expect(mo.read_users).to contain_exactly('mo_user')
        expect(mo.read_groups).to contain_exactly('mo_group', 'registered')
        expect(mo.visibility).to eq('restricted')
      end
    end

    context "with cdl disabled" do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false) }
      it "does not change item lending period or other fields" do
        BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, true, 'lending_period'
        mo.reload
        expect(mo.lending_period).not_to eq(co.default_lending_period)
        expect(mo.hidden?).to be_falsey
        expect(mo.read_users).to contain_exactly('mo_user')
        expect(mo.read_groups).to contain_exactly('mo_group', 'registered')
        expect(mo.visibility).to eq('restricted')
      end
    end

    context "overwrite is true" do
      it "replaces existing Special Access but affects no other fields" do
        BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, true, 'special_access'
        mo.reload
        expect(mo.read_users).to contain_exactly("co_user")
        expect(mo.read_groups).to contain_exactly("co_group", "registered")
        expect(mo.hidden?).to be_falsey
        expect(mo.visibility).to eq('restricted')
        expect(mo.lending_period).to eq(1209600)
        solr_doc = ActiveFedora::SolrService.query("id:#{mo.id}").first
        expect(solr_doc["read_access_person_ssim"]).to contain_exactly("co_user")
        expect(solr_doc["read_access_group_ssim"]).to contain_exactly("co_group", "registered")
      end
    end

    context "overwrite is false" do
      it "adds to existing Special Access but affects no other fields" do
        BulkActionJobs::ApplyCollectionAccessControl.perform_now co.id, false, 'special_access'
        mo.reload
        expect(mo.read_users).to contain_exactly("mo_user", "co_user")
        expect(mo.read_groups).to contain_exactly("mo_group", "co_group", "registered")
        expect(mo.hidden?).to be_falsey
        expect(mo.visibility).to eq('restricted')
        expect(mo.lending_period).to eq(1209600)
        solr_doc = ActiveFedora::SolrService.query("id:#{mo.id}").first
        expect(solr_doc["read_access_person_ssim"]).to contain_exactly("mo_user", "co_user")
        expect(solr_doc["read_access_group_ssim"]).to contain_exactly("mo_group", "co_group", "registered")
      end
    end
  end
end

describe BulkActionJobs::ReturnCheckouts do
  let(:collection_1) { FactoryBot.create(:collection, items: 2) }
  let(:collection_2) { FactoryBot.create(:collection, items: 1) }
  let!(:checkout_1) { FactoryBot.create(:checkout, media_object_id: collection_1.media_object_ids[0]) }
  let!(:checkout_2) { FactoryBot.create(:checkout, media_object_id: collection_1.media_object_ids[1]) }
  let!(:checkout_3) { FactoryBot.create(:checkout, media_object_id: collection_2.media_object_ids[0]) }

  it 'returns checkouts for the input collection' do
    # byebug
    BulkActionJobs::ReturnCheckouts.perform_now(collection_1.id)
    checkout_1.reload
    checkout_2.reload
    expect(checkout_1.return_time).to be < DateTime.current.to_time
    expect(checkout_2.return_time).to be < DateTime.current.to_time
  end

  it 'does not return checkouts for other collections' do
    BulkActionJobs::ReturnCheckouts.perform_now(collection_1.id)
    checkout_3.reload
    expect(checkout_3.return_time).to be >= DateTime.current.to_time
  end
end
