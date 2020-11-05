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

describe BatchScanJob do
  let(:ingest) { double(Avalon::Batch::Ingest) }

  before do
    collection = FactoryBot.create(:collection)
    allow(Avalon::Batch::Ingest).to receive(:new).and_return(ingest)
    allow(ingest).to receive(:scan_for_packages)
  end

  describe "perform" do
    it 'scans for packages' do
      expect(ingest).to receive(:scan_for_packages)
      BatchScanJob.perform_now
    end
  end
end
