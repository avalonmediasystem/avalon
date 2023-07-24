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

describe SpeedyAF::Proxy::MediaObject do
  let(:media_object) { FactoryBot.create(:media_object) }
  subject(:presenter) { described_class.find(media_object.id) }

  describe "#visibility" do
    context 'when private' do
      it 'returns private' do
        expect(presenter.visibility).to eq 'private'
      end
    end
    context 'when protected' do
      let(:media_object) { FactoryBot.create(:media_object, visibility: 'restricted') }
      it 'returns restricted' do
        expect(presenter.visibility).to eq 'restricted'
      end
    end
    context 'when public' do
      let(:media_object) { FactoryBot.create(:media_object, visibility: 'public') }
      it 'returns public' do
        expect(presenter.visibility).to eq 'public'
      end
    end
  end
end
