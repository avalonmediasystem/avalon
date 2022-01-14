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

describe MigrationStatusController do
  let(:obj) { FactoryBot.create(:master_file, migrated_from: [fedora3_pid]) }
  let(:fedora3_pid) { 'avalon:12345' }
  let(:avalon_noid) { obj.id }

  describe 'security' do
    context 'not logged in' do
      it "all routes should redirect to restricted content page" do
        expect(get :index).to render_template('errors/restricted_pid')
        expect(get :show, params: { class: 'MediaObject' }).to render_template('errors/restricted_pid')
        expect(get :detail, params: { id: 'avalon:12345' }).to render_template('errors/restricted_pid')
        expect(get :report, params: { id: 'avalon:12345' }).to render_template('errors/restricted_pid')
      end
    end

    context 'with end-user' do
      before do
        login_as :user
      end

      it "all routes should redirect to restricted content page" do
        expect(get :index).to render_template('errors/restricted_pid')
        expect(get :show, params: { class: 'MediaObject' }).to render_template('errors/restricted_pid')
        expect(get :detail, params: { id: 'avalon:12345' }).to render_template('errors/restricted_pid')
        expect(get :report, params: { id: 'avalon:12345' }).to render_template('errors/restricted_pid')
      end
    end
  end

  describe '#detail' do
    before do
      login_as :administrator
      MigrationStatus.create!(f3_pid: fedora3_pid, f4_pid: avalon_noid, source_class: obj.class)
    end

    context 'with a Fedora 3 pid' do
      it 'returns the details' do
        get :detail, params: { id: fedora3_pid }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with an Avalon noid' do
      it 'returns the details' do
        get :detail, params: { id: avalon_noid }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
