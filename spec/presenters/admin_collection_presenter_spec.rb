# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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
require 'cancan/matchers'

describe Admin::CollectionPresenter do
  let(:id) {  "abcd12345" }
  let(:name) { "Sample Collection" }
  let(:unit) { "Default Unit" }
  let(:description) { "The long form description of this collection." }
  let(:managers) { [manager.to_s] }
  let(:editors) { [editor.to_s] }
  let(:depositors) { [depositor.to_s] }
  let(:manager) { FactoryBot.create(:manager) }
  let(:editor) { FactoryBot.create(:user) }
  let(:depositor) { FactoryBot.create(:user) }
  let(:solr_doc) do
    SolrDocument.new(
      id: id,
      "name_ssi": name,
      "unit_ssi": unit,
      "description_tesim": [description],
      "edit_access_person_ssim": managers + editors,
      "read_access_person_ssim": depositors
    )
  end
  subject(:presenter) { described_class.new(solr_doc) }

  it 'provides getters for descriptive fields' do
    expect(presenter.id).to eq id
    expect(presenter.name).to eq name
    expect(presenter.unit).to eq unit
    expect(presenter.description).to eq description
  end

  it 'provides access control information' do
    expect(presenter.managers).to eq managers
    expect(presenter.editors).to eq editors
    expect(presenter.depositors).to eq depositors
  end

  describe '#as_json' do
    subject(:presenter_json) { presenter.as_json({}) }
    it 'returns json' do
      expect(presenter_json[:id]).to eq id
      expect(presenter_json[:name]).to eq name
      expect(presenter_json[:unit]).to eq unit
      expect(presenter_json[:description]).to eq description
      expect(presenter_json[:object_count]).to be_present
      expect(presenter_json[:roles][:managers]).to eq managers
      expect(presenter_json[:roles][:editors]).to eq editors
      expect(presenter_json[:roles][:depositors]).to eq depositors
    end
  end

  describe 'abilities' do
    subject(:ability) { Ability.new(user, {}) }

    context 'when manager' do
      let(:user) { manager }

      it { is_expected.to be_able_to(:destroy, presenter) }
    end

    context 'when editor' do
      let(:user) { editor }

      it { is_expected.not_to be_able_to(:destroy, presenter) }
    end

    context 'when depositor' do
      let(:user) { depositor }

      it { is_expected.not_to be_able_to(:destroy, presenter) }
    end
  end
end
