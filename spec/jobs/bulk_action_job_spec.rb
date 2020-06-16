# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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
