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

require 'rails_helper'

describe SpeedyAF::Proxy::Lease do
  let(:lease) { FactoryBot.create(:lease, lease_type: "user") }
  subject(:presenter) { described_class.find(lease.id) }

  it "returns all fields" do
    expect(subject.begin_time).to be_present
    expect(subject.end_time).to be_present
    expect(subject.lease_type).to be_present
  end

  describe "#defaults" do
    let(:lease) { FactoryBot.create(:lease) }

    it "sets lease_type to nil" do
      expect(subject.inspect).to include("lease_type")
      expect(subject.lease_type).to be_nil
    end
  end
end
