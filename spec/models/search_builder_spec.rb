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

RSpec.describe SearchBuilder do
  subject(:builder) { described_class.new(processor_chain, scope) }

  let(:processor_chain) { [] }
  let(:scope) { CatalogController.new }
  let(:manager) { FactoryBot.create(:manager) }
  let(:ability) { Ability.new(manager) }

  describe "#only_published_items" do
    it "should include policy clauses when user is manager" do
      allow(subject).to receive(:current_ability).and_return(ability)
      allow(subject).to receive(:policy_clauses).and_return("test:clause")
      expect(subject.only_published_items({})).to eq "test:clause OR workflow_published_sim:\"Published\""
    end
  end

  describe "#strip_extra_colons" do
    it "should remove all unquoted colons" do
      expect(subject.strip_extra_colons({q: "a : b : c : d"})).to eq "a  b  c  d"
      expect(subject.strip_extra_colons({q: "\"a : b\" : c : d"})).to eq "\"a : b\"  c  d"
    end
  end
end
