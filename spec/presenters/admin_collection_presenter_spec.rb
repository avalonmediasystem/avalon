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
require 'cancan/matchers'

describe Admin::CollectionPresenter do
  let(:id) {  "abcd12345" }
  let(:name) { "Sample Collection" }
  let(:unit_name) { "Default Unit" }
  let(:description) { "The long form description of this collection." }
  let(:managers) { [manager.to_s] }
  let(:editors) { [editor.to_s, FactoryBot.create(:manager).to_s] }
  let(:depositors) { [depositor.to_s] }
  let(:manager) { FactoryBot.create(:manager) }
  let(:editor) { FactoryBot.create(:user) }
  let(:depositor) { FactoryBot.create(:user) }
  let(:unit) { FactoryBot.create(:unit, name: unit_name) }
  let(:collection) { FactoryBot.create(:collection, id: id, name: name, unit: unit, description: description, managers: managers, editors: editors, depositors: depositors) }
  let(:solr_doc) { SolrDocument.new(collection.to_solr) }
  subject(:presenter) { described_class.new(solr_doc) }

  it 'provides getters for descriptive fields' do
    expect(presenter.id).to eq id
    expect(presenter.name).to eq name
    expect(presenter.unit).to eq unit_name
    expect(presenter.description).to eq description
  end

  it 'provides access control information' do
    expect(presenter.managers).to match_array managers
    expect(presenter.editors).to match_array editors
    expect(presenter.depositors).to match_array depositors
  end

  describe '#as_json' do
    subject(:presenter_json) { presenter.as_json({}) }
    it 'returns json' do
      expect(presenter_json[:id]).to eq id
      expect(presenter_json[:name]).to eq name
      expect(presenter_json[:unit]).to eq unit_name
      expect(presenter_json[:description]).to eq description
      expect(presenter_json[:object_count]).to be_present
      expect(presenter_json[:roles][:managers]).to match_array managers
      expect(presenter_json[:roles][:editors]).to match_array editors
      expect(presenter_json[:roles][:depositors]).to match_array depositors
    end
  end

  describe 'abilities' do
    subject(:ability) { Ability.new(User.where(Devise.authentication_keys.first => user).first) }

    context 'when manager' do
      let(:user) { manager }

      it { is_expected.not_to be_able_to(:destroy, presenter) }

      context 'inherited from unit' do
        let(:user) { presenter.inherited_managers.first }

        it { is_expected.to be_able_to(:destroy, presenter) }
      end
    end

    context 'when editor' do
      let(:user) { editor }

      it { is_expected.not_to be_able_to(:destroy, presenter) }

      context 'inherited from unit' do
        let(:user) { presenter.inherited_editors.first }

        it { is_expected.not_to be_able_to(:destroy, presenter) }
      end
    end

    context 'when depositor' do
      let(:user) { depositor }

      it { is_expected.not_to be_able_to(:destroy, presenter) }

      context 'inherited from unit' do
        let(:user) { presenter.inherited_depositors.first }

        it { is_expected.not_to be_able_to(:destroy, presenter) }
      end
    end
  end
end
