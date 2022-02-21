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

describe CollectionsController, type: :controller do
  # TODO: replace the fedora creates with solr mocking?
  let!(:collection) { FactoryBot.create(:collection, items: 1) }

  describe 'security' do
    context 'with end-user' do
      before do
        login_as :user
      end
      it "all routes should redirect to restricted content page" do
        expect(get :show, params: { id: collection.id }).to render_template('errors/restricted_pid')
        expect(get :poster, params: { id: collection.id }).to render_template('errors/restricted_pid')
      end
    end

    context 'with unauthenticated user' do
      it "all routes should redirect to restricted content page" do
        expect(get :show, params: { id: collection.id }).to render_template('errors/restricted_pid')
        expect(get :poster, params: { id: collection.id }).to render_template('errors/restricted_pid')
      end
    end
  end

  describe "#index" do
    context 'gated discovery' do
      let!(:collection2) { FactoryBot.create(:collection, items: 1) }
      let!(:collection3) { FactoryBot.create(:collection) }
      let!(:collection4) { FactoryBot.create(:collection) }
      let!(:collection5) { FactoryBot.create(:collection) }
      let!(:public_media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection3) }
      let!(:unpublished_public_media_object) { FactoryBot.create(:fully_searchable_media_object, avalon_publisher: nil, collection: collection4) }
      let!(:hidden_public_media_object) { FactoryBot.create(:fully_searchable_media_object, hidden: true, collection: collection5) }

      it "admin should see all collections" do
        login_as :administrator
        get 'index'
        expect(response).to be_ok
        expect(assigns(:doc_presenters).count).to eql(5)
        expect(assigns(:doc_presenters).map(&:id)).to match_array([collection.id, collection2.id, collection3.id, collection4.id, collection5.id])
      end

      it "managers should see their collections and collections with public items" do
        login_user(collection.managers.first)
        get 'index'
        expect(response).to be_ok
        expect(assigns(:doc_presenters).count).to eql(3)
        expect(assigns(:doc_presenters).map(&:id)).to match_array([collection.id, collection3.id, collection4.id])
      end

      it "end users should see collections with published, non-hidden, public items" do
        login_as :user
        get 'index'
        expect(response).to be_ok
        expect(assigns(:doc_presenters).count).to eql(1)
        expect(assigns(:doc_presenters).map(&:id)).to match_array([collection3.id])
      end
    end

    context 'format json' do
      it 'returns json' do
        login_as :administrator
        get 'index', params: { format: :json }
        expect(response).to be_ok
        expect(response.content_type).to eq "application/json; charset=utf-8"
        expect(assigns(:doc_presenters).count).to eql(1)
        expect(assigns(:doc_presenters).map(&:id)).to match_array([collection.id])
      end
    end

    context 'only carousel' do
      let!(:collection2) { FactoryBot.create(:collection, items: 1) }
      let(:home_page_config) { { home_page: { carousel_collections: [collection2.id] } } }

      around(:example) do |example|
        Settings.add_source!(home_page_config)
        Settings.reload!
        example.run
        Settings.instance_variable_get(:@config_sources).pop
        Settings.reload!
      end

      it 'filters results by id' do
        login_as :administrator
        get 'index', params: { only: "carousel" }
        expect(response).to be_ok
        expect(assigns(:doc_presenters).count).to eql(1)
        expect(assigns(:doc_presenters).map(&:id)).to match_array([collection2.id])
      end
    end

    context 'with limit' do
      let!(:collection2) { FactoryBot.create(:collection, items: 1) }

      it 'limits the number of results returned' do
        login_as :administrator
        get 'index', params: { limit: 1 }
        expect(response).to be_ok
        expect(assigns(:doc_presenters).count).to eql(1)
        expect([collection.id, collection2.id]).to include(*assigns(:doc_presenters).map(&:id))
      end
    end
  end

  describe "#show" do
    it "should allow access to managers" do
      login_user(collection.managers.first)
      get 'show', params: { id: collection.id }
      expect(response).to be_ok
      expect(response).to render_template(:show)
      expect(assigns(:doc_presenter).id).to eq collection.id
    end

    context 'format json' do
      it 'returns json' do
        login_as :administrator
        get 'show', params: { id: collection.id, format: :json }
        expect(response).to be_ok
        expect(response.content_type).to eq "application/json; charset=utf-8"
        expect(assigns(:doc_presenter).id).to eq collection.id
        end
    end
  end

  describe '#poster' do
    let!(:collection) { FactoryBot.create(:collection, :with_poster, items: 1) }

    before do
      login_as :administrator
    end

    it 'returns the poster image' do
      get 'poster', params: { id: collection.id }
      expect(response).to be_ok
      expect(response.content_type).to eq 'image/png; charset=utf-8'
    end

    context 'when the collection does not have a poster image' do
      let!(:collection) { FactoryBot.create(:collection, items: 1) }

      it 'returns 404' do
        get 'poster', params: { id: collection.id }
        expect(response).to be_not_found
      end
    end
  end
end
