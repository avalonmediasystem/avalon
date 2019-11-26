# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

describe CatalogController do
  describe "#index" do
    describe "as an un-authenticated user" do
      it "should show results for items that are public and published" do
        mo = FactoryBot.create(:published_media_object, visibility: 'public')
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
      it "should not show results for items that are not public" do
        mo = FactoryBot.create(:published_media_object, visibility: 'restricted')
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
      it "should not show results for items that are not published" do
        mo = FactoryBot.create(:media_object, visibility: 'public')
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
    end
    describe "as an authenticated user" do
      before do
        login_as :user
      end
      it "should show results for items that are published and available to registered users" do
        mo = FactoryBot.create(:published_media_object, visibility: 'restricted')
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
      it "should not show results for items that are not public or available to registered users" do
        mo = FactoryBot.create(:published_media_object, visibility: 'private')
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
      it "should not show results for items that are not published" do
        mo = FactoryBot.create(:media_object, visibility: 'public')
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
    end
    describe "as a manager" do
      let!(:collection) {FactoryBot.create(:collection)}
      let!(:manager) {login_user(collection.managers.first)}

      it "should show results for items that are unpublished, private, and belong to one of my collections" do
        mo = FactoryBot.create(:media_object, visibility: 'private', collection: collection)
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
      it "should show results for items that are hidden and belong to one of my collections" do
        mo = FactoryBot.create(:media_object, hidden: true, visibility: 'private', collection: collection)
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
      it "should show results for items that are not hidden and do not belong to one of my collections along with hidden items that belong to my collections" do
        mo = FactoryBot.create(:media_object, hidden: true, visibility: 'private', collection: collection)
        mo2 = FactoryBot.create(:fully_searchable_media_object)
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(2)
        expect(assigns(:document_list).map(&:id)).to match_array([mo.id, mo2.id])
      end
      it "should not show results for items that do not belong to one of my collections" do
        mo = FactoryBot.create(:media_object, visibility: 'private')
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
      it "should not show results for hidden items that do not belong to one of my collections" do
        mo = FactoryBot.create(:media_object, hidden: true, visibility: 'private', read_users: [manager.user_key])
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
    end
    describe "as an administrator" do
      let!(:administrator) {login_as(:administrator)}

      it "should show results for all items" do
        mo = FactoryBot.create(:media_object, visibility: 'private')
        get 'index', params: { :q => "" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
    end
    describe "as an lti user" do
      let!(:user) { login_lti 'student' }
      let!(:lti_group) { @controller.user_session[:virtual_groups].first }
      it "should show results for items visible to the lti virtual group" do
        mo = FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
        get 'index', params: { :q => "read_access_virtual_group_ssim:#{lti_group}" }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
    end

    describe "as an unauthenticated user with a specific IP address" do
      before(:each) do
        @user = login_as 'public'
        @ip_address1 = Faker::Internet.ip_v4_address
        @mo = FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [@ip_address1])
      end
      it "should show no results when no items are visible to the user's IP address" do
        get 'index', params: { :q => "" }
        expect(assigns(:document_list).count).to eq 0
      end
      it "should show results for items visible to the the user's IP address" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(@ip_address1)
        get 'index', params: { :q => "" }
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to include @mo.id
      end
      it "should show results for items visible to the the user's IPv4 subnet" do
        ip_address2 = Faker::Internet.ip_v4_address
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(ip_address2)
        mo2 = FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [ip_address2+'/30'])
        get 'index', params: { :q => "" }
        expect(assigns(:document_list).count).to be >= 1
        expect(assigns(:document_list).map(&:id)).to include mo2.id
      end
      it "should show results for items visible to the the user's IPv6 subnet" do
        ip_address3 = Faker::Internet.ip_v6_address
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(ip_address3)
        mo3 = FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [ip_address3+'/ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00'])
        get 'index', params: { :q => "" }
        expect(assigns(:document_list).count).to be >= 1
        expect(assigns(:document_list).map(&:id)).to include mo3.id
      end
    end

    describe "search fields" do
      let(:media_object) { FactoryBot.create(:fully_searchable_media_object) }
      ["title_tesi", "creator_ssim", "contributor_sim", "unit_ssim", "collection_ssim", "summary_ssi", "publisher_sim", "subject_topic_sim", "subject_geographic_sim", "subject_temporal_sim", "genre_sim", "physical_description_sim", "language_sim", "date_sim", "notes_sim", "table_of_contents_sim", "other_identifier_sim" ].each do |field|
        it "should find results based upon #{field}" do
          query = Array(media_object.to_solr[field]).first
          #split on ' ' and only search on the first word of a multiword field value
          query = query.split(' ').first
          #The following line is to check that the test is using a valid solr field name
          #since an incorrect one will lead to an empty query resulting in a false positive below
          expect(query).not_to be_empty
          get 'index', params: { :q => query }
          expect(assigns(:document_list).count).to eq 1
          expect(assigns(:document_list).map(&:id)). to eq [media_object.id]
        end
      end
    end
    describe "search structure" do
      before(:each) do
        @media_object = FactoryBot.create(:fully_searchable_media_object)
        @master_file = FactoryBot.create(:master_file, :with_structure, media_object: @media_object, title: 'Test Label')
        @media_object.ordered_master_files += [@master_file]
        @media_object.save!
      end
      it "should find results based upon structure" do
        get 'index', params: { q: 'CD 1' }
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).collect(&:id)). to eq [@media_object.id]
      end
      it 'should find results based upon section labels' do
        get 'index', params: { q: 'Test Label' }
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).collect(&:id)). to eq [@media_object.id]
      end
      it 'should find items in correct relevancy order' do
        media_object_1 = FactoryBot.create(:fully_searchable_media_object, title: 'Test Label')
        get 'index', params: { q: 'Test Label' }
        expect(assigns(:document_list).count).to eq 2
        expect(assigns(:document_list).collect(&:id)).to eq [media_object_1.id, @media_object.id]
      end
    end

    describe "sort fields" do
      let!(:m1) { FactoryBot.create(:published_media_object, title: 'Yabba', date_issued: '1960', creator: ['Fred'], visibility: 'public') }
      let!(:m2) { FactoryBot.create(:published_media_object, title: 'Dabba', date_issued: '1970', creator: ['Betty'], visibility: 'public') }
      let!(:m3) { FactoryBot.create(:published_media_object, title: 'Doo', date_issued: '1980', creator: ['Wilma'], visibility: 'public') }

      it "should sort correctly by title" do
        get :index, params: { :sort => 'title_ssort asc, date_ssi desc' }
        expect(assigns(:document_list).map(&:id)).to eq [m2.id, m3.id, m1.id]
      end
      it "should sort correctly by date" do
        get :index, params: { :sort => 'date_ssi desc, title_ssort asc' }
        expect(assigns(:document_list).map(&:id)).to eq [m3.id, m2.id, m1.id]
      end
      it "should sort correctly by creator" do
        get :index, params: { :sort => 'creator_ssort asc, title_ssort asc' }
        expect(assigns(:document_list).map(&:id)).to eq [m2.id, m1.id, m3.id]
      end
    end

    describe "gated discovery" do
      context "with bad ldap groups" do
        let(:ldap_groups) { ['good-group', 'bad group'] }
        let!(:media_object) { FactoryBot.create(:published_media_object, read_groups: ['bad group']) }
        before do
          login_as :user
          controller.user_session[:virtual_groups] = ldap_groups
        end
        it "gracefully handles bad ldap groups" do
          get :index, params: { q: "" }
          expect(response).to be_successful
          expect(response).to render_template('catalog/index')
          expect(assigns(:document_list).count).to eq 1
          expect(assigns(:document_list).collect(&:id)). to eq [media_object.id]
        end
      end
    end

    describe "atom feed" do
      let!(:private_media_object) { FactoryBot.create(:media_object, visibility: 'private') }
      let!(:public_media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
      let(:administrator) { FactoryBot.create(:administrator) }

      context "with an api key" do
        before do
          ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
        end
        it "should show results for all items" do
          request.headers['Avalon-Api-Key'] = 'secret_token'
          get 'index', params: { q: "", format: 'atom' }
          expect(response).to be_successful
          expect(response).to render_template('catalog/index')
          expect(response.content_type).to eq "application/atom+xml"
          expect(assigns(:document_list).count).to eq 2
          expect(assigns(:document_list).map(&:id)).to match_array [private_media_object.id, public_media_object.id]
        end
      end
      context "without api key" do
        it "should not show results" do
          get 'index', params: { q: "", format: 'atom' }
          expect(response).to be_successful
          expect(response.content_type).to eq "application/atom+xml"
          expect(response).to render_template('catalog/index')
          expect(assigns(:document_list).count).to eq 1
          expect(assigns(:document_list).map(&:id)).to eq([public_media_object.id])
        end
      end
    end

    describe "home page" do
      let!(:collection) { FactoryBot.create(:collection, items: 1) }
      let(:home_page_config) { { home_page: { featured_collections: [collection.id] } } }

      around(:example) do |example|
        Settings.add_source!(home_page_config)
        Settings.reload!
        example.run
        Settings.instance_variable_get(:@config_sources).pop
        Settings.reload!
      end

      before do
        login_as :administrator
      end

      it 'loads featured collection' do
        expect(controller).to receive(:load_home_page_collections).and_call_original
        get 'index'
        expect(assigns(:featured_collection)).to be_present
        expect(assigns(:featured_collection)).to be_a Admin::CollectionPresenter
        expect(assigns(:featured_collection).id).to eq collection.id
      end

      context 'when there are multiple featured collections' do
        let!(:collections) { [FactoryBot.create(:collection, items: 1), FactoryBot.create(:collection, items: 1)] }
        let(:home_page_config) { { home_page: { featured_collections: collections.map(&:id) } } }

        it 'loads featured collection' do
          expect(controller).to receive(:load_home_page_collections).and_call_original
          get 'index'
          expect(assigns(:featured_collection)).to be_present
          expect(assigns(:featured_collection)).to be_a Admin::CollectionPresenter
          expect(Settings.home_page.featured_collections).to include assigns(:featured_collection).id
        end
      end

      context 'when featured collections is not configured' do
        let(:home_page_config) { { home_page: nil } }

        it 'loads featured collection' do
          expect(controller).to receive(:load_home_page_collections).and_call_original
          get 'index'
          expect(assigns(:featured_collection)).not_to be_present
        end
      end

      context 'when not home page' do
        before do
          allow(controller.helpers).to receive(:current_page?).with(root_path).and_return(false)
        end

        it 'does not load featured collection' do
          expect(controller).not_to receive(:load_home_page_collections)
          get 'index', params: { :q => "" }
          expect(assigns(:featured_collection)).not_to be_present
        end
      end
    end
  end
end
