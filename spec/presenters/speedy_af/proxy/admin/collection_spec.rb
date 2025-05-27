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

describe SpeedyAF::Proxy::Admin::Collection do
  let(:collection) { FactoryBot.create(:collection) }
  let(:presenter) { described_class.find(collection.id) }

  describe 'attributes' do
    let(:collection) { FactoryBot.create(:collection, dropbox_directory_name: "dir", identifier: ["1234"], default_lending_period: 10000, cdl_enabled: true, default_read_users: ['user1'], default_read_groups: ['group1'], default_hidden: true) }

    it 'returns all attributes' do
      expect(presenter.name).to be_present
      expect(presenter.unit).to be_present
      expect(presenter.description).to be_present
      expect(presenter.contact_email).to be_present
      expect(presenter.website_label).to be_present
      expect(presenter.website_url).to be_present
      expect(presenter.dropbox_directory_name).to be_present
      expect(presenter.default_read_groups).to be_present
      expect(presenter.default_read_users).to be_present
      expect(presenter.default_hidden).not_to be_nil
      expect(presenter.identifier).to be_present
      expect(presenter.default_lending_period).to be_present
      expect(presenter.cdl_enabled).not_to be_nil
      expect(presenter.collection_managers).to be_present
      expect(presenter.edit_users).to be_present
      expect(presenter.read_users).to be_present
    end
  end

  describe 'cdl_enabled' do
    context 'collections disabled at the application level' do
      before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(false) }
      it 'sets collection cdl to be disabled by default' do
        expect(presenter.cdl_enabled?).to be false
      end
      context 'turned on for collection' do
        let(:collection2) { FactoryBot.create(:collection, cdl_enabled: true) }
        let(:presenter2) { described_class.find(collection2.id) }
        it 'does not affect other collections' do
          expect(presenter.cdl_enabled?).to be false
          expect(presenter2.cdl_enabled?).to be true
        end
      end
    end
    context 'collections enabled at the application level' do
      before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }
      it 'sets collection cdl to be enabled by default' do
        expect(presenter.cdl_enabled?).to be true
      end 
      context 'turned off for collection' do
        let(:collection2) { FactoryBot.create(:collection, cdl_enabled: false) }
        let(:presenter2) { described_class.find(collection2.id) }
        it 'does not affect other collections' do
          expect(presenter.cdl_enabled?).to be true
          expect(presenter2.cdl_enabled?).to be false 
        end
      end
    end
  end
end
