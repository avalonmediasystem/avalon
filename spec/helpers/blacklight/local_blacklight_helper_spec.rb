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

describe Blacklight::LocalBlacklightHelper do
  describe '#humanized_date_index_display' do
    let(:args) { { document: document, field: 'date_issued_ssi' } }

    context 'with valid date' do
      let(:document) { SolrDocument.new(date_issued_ssi: "2025-07-15") }

      it 'returns a human readable string' do
        expect(helper.humanized_date_index_display(args)).to eq "July 15, 2025"
      end
    end

    context 'with unknown/unknown' do
      let(:document) { SolrDocument.new(date_issued_ssi: "unknown/unknown") }

      it 'returns "unknown"' do
        expect(helper.humanized_date_index_display(args)).to eq "unknown"
      end
    end

    context 'with other non-edtf entries' do
      let(:document) { SolrDocument.new(date_issued_ssi: "not_a_date") }

      it 'returns nil' do
        expect(helper.humanized_date_index_display(args)).to be_nil
      end
    end
  end
end
