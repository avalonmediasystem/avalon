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

describe SpeedyAF::Proxy::Admin::Collection do
  let(:collection) { FactoryBot.create(:collection) }
  let(:presenter) { described_class.find(collection.id) }

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
