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

RSpec.describe "/admin/dashboard", type: :request do
  describe 'GET /index' do
    let(:collection) { FactoryBot.create(:collection, name: 'Test Collection') }
    let(:unit) { collection.unit }

    before do
      unit.name = 'Test Unit'
      unit.save
    end

    context 'unauthenticated user' do
      it "renders the restricted content page" do
        get admin_dashboard_url
        expect(response).to render_template(:restricted_pid)
      end
    end

    context 'authenticated' do
      before { sign_in(user) }

      context 'regular user' do
        let(:user) { FactoryBot.create(:user) }

        it "renders the restricted content page" do
          get admin_dashboard_url
          expect(response).to render_template(:restricted_pid)
        end
      end

      context 'collection manager' do
        let(:user) { User.where(username: collection.managers.first).first }

        it "renders the index partial and displays only collections" do
          get admin_dashboard_url
          expect(response).to be_successful
          expect(response).to render_template(:index)
          expect(response.body).to include 'Test Collection'
          expect(response.body).to include 'You don\'t have any units yet'
          expect(response.body).to_not include 'Test Unit'
        end
      end

      context 'unit administrator' do
        let(:user) { User.where(username: unit.unit_admins.first).first }

        it "renders the index partial and displays units and collections" do
          get admin_dashboard_url
          expect(response).to be_successful
          expect(response).to render_template(:index)
          expect(response.body).to include 'Test Collection'
          expect(response.body).to include 'Test Unit'
        end
      end
    end
  end
end
