# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

      context 'collection member' do
        let(:user) { User.where(username: collection.editors.first).first }

        it "returns collection data and no unit data" do
          get admin_dashboard_url
          expect(response).to be_successful
          expect(response).to render_template(:index)

          get admin_dashboard_url(format: :json)
          json = JSON.parse(response.body)
          expect(json['collections'].map { |c| c['name'] }).to include('Test Collection')
          expect(json['units']).to be_empty
        end

        context "with separate administrative access who has special access applied at unit" do
          let(:user) { FactoryBot.create(:user) }
          let!(:other_collection) { FactoryBot.create(:collection, name: 'Other Collection', editors: [user.user_key]) }

          before do
            collection.unit.default_read_users += [user.user_key]
            collection.unit.save
          end

          it "returns correct collection data" do
            get admin_dashboard_url
            expect(response).to be_successful
            expect(response).to render_template(:index)

            get admin_dashboard_url(format: :json)
            json = JSON.parse(response.body)
            expect(json['collections'].map { |c| c['name'] }).to include('Other Collection')
            expect(json['collections'].map { |c| c['name'] }).not_to include('Test Collection')
            expect(json['units']).to be_empty
          end
        end
      end

      context 'collection manager' do
        let(:user) { User.where(username: collection.managers.first).first }

        it "returns collection data and no unit data" do
          get admin_dashboard_url
          expect(response).to be_successful
          expect(response).to render_template(:index)

          get admin_dashboard_url(format: :json)
          json = JSON.parse(response.body)
          expect(json['collections'].map { |c| c['name'] }).to include('Test Collection')
          expect(json['units']).to be_empty
        end

        it "includes remove_url for collections the manager can destroy" do
          get admin_dashboard_url(format: :json)
          json = JSON.parse(response.body)
          test_collection = json['collections'].find { |c| c['name'] == 'Test Collection' }
          expect(test_collection['remove_url']).to eq("/admin/collections/#{collection.id}/remove")
        end
      end

      context 'collection editor' do
        let(:user) { User.where(username: collection.editors.first).first }

        it "omits remove_url for collections the editor cannot destroy" do
          get admin_dashboard_url(format: :json)
          json = JSON.parse(response.body)
          test_collection = json['collections'].find { |c| c['name'] == 'Test Collection' }
          expect(test_collection['remove_url']).to be_nil
        end
      end

      context 'unit administrator' do
        let(:user) { User.where(username: unit.unit_admins.first).first }

        it "returns both unit and collection data" do
          get admin_dashboard_url
          expect(response).to be_successful
          expect(response).to render_template(:index)

          get admin_dashboard_url(format: :json)
          json = JSON.parse(response.body)
          expect(json['collections'].map { |c| c['name'] }).to include('Test Collection')
          expect(json['units'].map { |u| u['name'] }).to include('Test Unit')
        end

        it "includes remove_url for units the unit admin can destroy" do
          get admin_dashboard_url(format: :json)
          json = JSON.parse(response.body)
          test_unit = json['units'].find { |u| u['name'] == 'Test Unit' }
          expect(test_unit['remove_url']).to eq("/admin/units/#{unit.id}/remove")
        end

        it "includes remove_url for collections inherited via unit admin role" do
          get admin_dashboard_url(format: :json)
          json = JSON.parse(response.body)
          test_collection = json['collections'].find { |c| c['name'] == 'Test Collection' }
          expect(test_collection['remove_url']).to eq("/admin/collections/#{collection.id}/remove")
        end
      end
    end
  end
end
