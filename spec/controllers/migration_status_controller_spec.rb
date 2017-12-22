# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

describe MigrationStatusController do
  let(:obj) { FactoryGirl.create(:master_file, migrated_from: [fedora3_pid]) }
  let(:fedora3_pid) { 'avalon:12345' }
  let(:avalon_noid) { obj.id }

  before do
    login_as :administrator
    MigrationStatus.create!(f3_pid: fedora3_pid, f4_pid: avalon_noid, source_class: obj.class)
  end

  describe '#detail' do
    context 'with a Fedora 3 pid' do
      it 'returns the details' do
        get :detail, id: fedora3_pid
        expect(response).to have_http_status(:ok)
      end
    end
    context 'with an Avalon noid' do
      it 'returns the details' do
        get :detail, id: avalon_noid
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
