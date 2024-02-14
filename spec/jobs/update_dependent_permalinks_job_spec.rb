# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe UpdateDependentPermalinksJob do
  let(:media_object) { instance_double('MediaObject', id: 'abcd1234') }
  subject { described_class.new }

  describe 'perform' do
    context 'when object exists' do
      before do
        allow(MediaObject).to receive(:exists?).and_return(true)
        allow(MediaObject).to receive(:find).and_return(media_object)
      end
      it 'calls update_dependent_permalinks' do
        expect(media_object).to receive(:update_dependent_permalinks)
        subject.perform(media_object.id)
      end
    end
    context 'when object does not exist' do
      before do
        allow(MediaObject).to receive(:exists?).and_return(false)
      end
      it 'does not call find' do
        expect(MediaObject).not_to receive(:find)
        subject.perform(media_object.id)
      end
    end
  end
end
