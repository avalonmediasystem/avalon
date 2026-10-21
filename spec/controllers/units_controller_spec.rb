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

describe UnitsController, type: :controller do
  # TODO: replace the fedora creates with solr mocking?
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:collection) { FactoryBot.create(:collection, items: 1, unit: unit) }

  describe 'security' do
    context 'with end-user' do
      before do
        login_as :user
      end
      it "all routes should redirect to restricted content page" do
        expect(get :show, params: { id: unit.id }).to render_template('errors/restricted_pid')
        expect(get :poster, params: { id: unit.id }).to render_template('errors/restricted_pid')
      end
    end

    context 'with unauthenticated user' do
      it "all routes should redirect to restricted content page" do
        expect(get :show, params: { id: unit.id }).to render_template('errors/restricted_pid')
        expect(get :poster, params: { id: unit.id }).to render_template('errors/restricted_pid')
      end
    end
  end

  describe "#index" do
    context 'gated discovery' do
      let!(:unit2) { FactoryBot.create(:unit) }
      let!(:unit3) { FactoryBot.create(:unit) }
      let!(:unit4) { FactoryBot.create(:unit) }
      let!(:unit5) { FactoryBot.create(:unit) }
      let!(:collection2) { FactoryBot.create(:collection, items: 1, unit: unit2) }
      let!(:collection3) { FactoryBot.create(:collection, unit: unit3) }
      let!(:collection4) { FactoryBot.create(:collection, unit: unit4) }
      let!(:collection5) { FactoryBot.create(:collection, unit: unit5) }
      let!(:public_media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection3) }
      let!(:unpublished_public_media_object) { FactoryBot.create(:fully_searchable_media_object, avalon_publisher: nil, collection: collection4) }
      let!(:hidden_public_media_object) { FactoryBot.create(:fully_searchable_media_object, hidden: true, collection: collection5) }

      it "admin should see all units" do
        login_as :administrator
        get 'index'
        expect(response).to be_ok
        expect(assigns(:doc_presenters).count).to eql(5)
        expect(assigns(:doc_presenters).map(&:id)).to match_array([unit.id, unit2.id, unit3.id, unit4.id, unit5.id])
      end

      it "managers should see their units and units with published public items" do
        login_user(unit.managers.first)
        get 'index'
        expect(response).to be_ok
        expect(assigns(:doc_presenters).count).to eql(2)
        expect(assigns(:doc_presenters).map(&:id)).to match_array([unit.id, unit3.id])
      end

      context 'as end user' do
        before do
          login_as :user
        end

        it "end users should see units with published, non-hidden, public items" do
          get 'index'
          expect(response).to be_ok
          expect(assigns(:doc_presenters).count).to eql(1)
          expect(assigns(:doc_presenters).map(&:id)).to match_array([unit3.id])
        end

        context 'with inheritance' do
          let!(:collection3) { FactoryBot.create(:collection, default_visibility: 'private', unit: unit3) }

          context 'with private item' do
            let!(:public_media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection3, disable_inheritance: false, visibility: 'private') }

            it "end users should not see units with only private items" do
              get 'index'
              expect(response).to be_ok
              expect(assigns(:doc_presenters).count).to eql(0)
            end
          end

          context 'with saved non-active visibility' do
            let!(:public_media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection3, disable_inheritance: false, visibility: 'public') }

            it "end users should not see units with non-active public visibility items" do
              get 'index'
              expect(response).to be_ok
              expect(assigns(:doc_presenters).count).to eql(0)
            end
          end

          context 'with inheritance disabled' do
            let!(:public_media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection3, disable_inheritance: true, visibility: 'public') }

            it "end users should see units with public disable inheritance items" do
              get 'index'
              expect(response).to be_ok
              expect(assigns(:doc_presenters).count).to eql(1)
              expect(assigns(:doc_presenters).map(&:id)).to match_array([unit3.id])
            end
          end
        end
      end
    end

    context 'format json' do
      it 'returns json' do
        login_as :administrator
        get 'index', params: { format: :json }
        expect(response).to be_ok
        expect(response.content_type).to eq "application/json; charset=utf-8"
        expect(assigns(:doc_presenters).count).to eql(1)
        expect(assigns(:doc_presenters).map(&:id)).to match_array([unit.id])
      end
    end

    context 'with limit' do
      let!(:unit2) { FactoryBot.create(:unit) }
      let!(:collection2) { FactoryBot.create(:collection, items: 1, unit: unit2) }

      it 'limits the number of results returned' do
        login_as :administrator
        get 'index', params: { limit: 1 }
        expect(response).to be_ok
        expect(assigns(:doc_presenters).count).to eql(1)
        expect([unit.id, unit2.id]).to include(*assigns(:doc_presenters).map(&:id))
      end
    end
  end

  describe "#show" do
    it "should allow access to managers" do
      login_user(unit.managers.first)
      get 'show', params: { id: unit.id }
      expect(response).to be_ok
      expect(response).to render_template(:show)
      expect(assigns(:doc_presenter).id).to eq unit.id
    end

    context 'format json' do
      it 'returns json' do
        login_as :administrator
        get 'show', params: { id: unit.id, format: :json }
        expect(response).to be_ok
        expect(response.content_type).to eq "application/json; charset=utf-8"
        expect(assigns(:doc_presenter).id).to eq unit.id
      end
    end

    context 'as end user' do
      let!(:collection) { FactoryBot.create(:collection, default_visibility: 'private', unit: unit) }

      before do
        login_as :user
      end

      context 'with inheritance' do
        context 'with private item' do
          let!(:private_media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection, disable_inheritance: false, visibility: 'private') }

          it "end users should not see collection with only private items" do
            expect(get 'show', params: { id: unit.id }).to render_template('errors/restricted_pid')
          end
        end

        context 'with saved non-active visibility' do
          let!(:public_media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection, disable_inheritance: false, visibility: 'public') }

          it "end users should not see collection with non-active public visibility items" do
            expect(get 'show', params: { id: unit.id }).to render_template('errors/restricted_pid')
          end
        end
      end

      context 'with inheritance disabled' do
        let!(:public_media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection, disable_inheritance: true, visibility: 'public') }

        it "end users should see unit with public disable inheritance items" do
          get 'show', params: { id: unit.id }
          expect(response).to be_ok
          expect(assigns(:doc_presenter).id).to eq unit.id
        end
      end
    end
  end

  describe '#poster' do
    let!(:unit) { FactoryBot.create(:unit, :with_poster, items: 1) }

    before do
      login_as :administrator
    end

    it 'returns the poster image' do
      get 'poster', params: { id: unit.id }
      expect(response).to be_ok
      expect(response.content_type).to eq 'image/png; charset=utf-8'
    end

    context 'when the unit does not have a poster image' do
      let!(:unit) { FactoryBot.create(:unit, items: 1) }

      it 'returns 404' do
        get 'poster', params: { id: unit.id }
        expect(response).to be_not_found
      end
    end

    context 'read from solr' do
      it 'should not read from fedora' do
        WebMock.reset_executed_requests!
        get 'poster', params: { id: unit.id }
        expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
      end
    end
  end
end
