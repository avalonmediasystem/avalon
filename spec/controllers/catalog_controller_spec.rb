# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'spec_helper'

describe CatalogController do
  describe "#index" do
    describe "as an un-authenticated user" do
      it "should show results for items that are public and published" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'public')
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
      it "should not show results for items that are not public" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'restricted')
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
      it "should not show results for items that are not published" do
        mo = FactoryGirl.create(:media_object, visibility: 'public')
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
    end
    describe "as an authenticated user" do
      before do
        login_as :user
      end
      it "should show results for items that are published and available to registered users" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'restricted')
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
      it "should not show results for items that are not public or available to registered users" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'private')
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
      it "should not show results for items that are not published" do
        mo = FactoryGirl.create(:media_object, visibility: 'public')
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
    end
    describe "as a manager" do
      let!(:collection) {FactoryGirl.create(:collection)}
      let!(:manager) {login_user(collection.managers.first)}

      it "should show results for items that are unpublished, private, and belong to one of my collections" do
        mo = FactoryGirl.create(:media_object, visibility: 'private', collection: collection)
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
      it "should show results for items that are hidden and belong to one of my collections" do
        mo = FactoryGirl.create(:media_object, hidden: true, visibility: 'private', collection: collection)
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
      it "should not show results for items that do not belong to one of my collections" do
        mo = FactoryGirl.create(:media_object, visibility: 'private')
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
      it "should not show results for hidden items that do not belong to one of my collections" do
        mo = FactoryGirl.create(:media_object, hidden: true, visibility: 'private', read_users: [manager.username])
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(0)
      end
    end
    describe "as an administrator" do
      let!(:administrator) {login_as(:administrator)}

      it "should show results for all items" do
        mo = FactoryGirl.create(:media_object, visibility: 'private')
        get 'index', :q => ""
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
    end
    describe "as an lti user" do
      let!(:user) { login_lti 'student' }
      let!(:lti_group) { @controller.user_session[:virtual_groups].first }
      it "should show results for items visible to the lti virtual group" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
        get 'index', :q => "read_access_virtual_group_ssim:#{lti_group}"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list).map(&:id)).to eq([mo.id])
      end
    end

    describe "as an unauthenticated user with a specific IP address" do
      before(:each) do 
        @user = login_as 'public'
        @ip_address1 = Faker::Internet.ip_v4_address
        @mo = FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [@ip_address1]) 
      end
      it "should show no results when no items are visible to the user's IP address" do
        get 'index', :q => ""
        expect(assigns(:document_list).count).to eq 0
      end
      it "should show results for items visible to the the user's IP address" do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(@ip_address1)
        get 'index', :q => ""
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to include @mo.id
      end
      it "should show results for items visible to the the user's IPv4 subnet" do
        ip_address2 = Faker::Internet.ip_v4_address
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(ip_address2)
        mo2 = FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [ip_address2+'/30']) 
        get 'index', :q => ""
        expect(assigns(:document_list).count).to be >= 1
        expect(assigns(:document_list).map(&:id)).to include mo2.id
      end
      it "should show results for items visible to the the user's IPv6 subnet" do
        ip_address3 = Faker::Internet.ip_v6_address
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(ip_address3)
        mo3 = FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [ip_address3+'/ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00']) 
        get 'index', :q => ""
        expect(assigns(:document_list).count).to be >= 1
        expect(assigns(:document_list).map(&:id)).to include mo3.id
      end
    end

    describe "search fields" do
      let(:media_object) { FactoryGirl.create(:fully_searchable_media_object) }
#      ["title_tesi", "creator_ssim", "contributor_sim", "unit_ssim", "collection_ssim", "summary_ssi", "publisher_sim", "subject_topic_sim", "subject_geographic_sim", "subject_temporal_sim", "genre_sim", "physical_description_sim", "language_sim", "date_sim", "notes_sim", "table_of_contents_sim", "other_identifier_sim", "date_ingested_sim" ].each do |field|
      ["title_tesi", "creator_ssim", "contributor_sim", "unit_ssim", "collection_ssim", "summary_ssi", "publisher_sim", "subject_topic_sim", "subject_geographic_sim", "subject_temporal_sim", "genre_sim", "physical_description_sim", "language_sim", "date_sim", "notes_sim", "table_of_contents_sim", "other_identifier_sim" ].each do |field|
        it "should find results based upon #{field}" do
          query = Array(media_object.to_solr[field]).first
          #split on ' ' and only search on the first word of a multiword field value
          query = query.split(' ').first
          #The following line is to check that the test is using a valid solr field name
          #since an incorrect one will lead to an empty query resulting in a false positive below
          expect(query).not_to be_empty
          get 'index', :q => query
          expect(assigns(:document_list).count).to eq 1
          expect(assigns(:document_list).map(&:id)). to eq [media_object.id]
        end
      end
    end
    describe "search structure" do
      before(:each) do 
        @media_object = FactoryGirl.create(:fully_searchable_media_object)
        @master_file = FactoryGirl.create(:master_file_with_structure, mediaobject_id: @media_object.pid, label: 'Test Label')
        @media_object.parts += [@master_file]
        @media_object.save!
      end
      it "should find results based upon structure" do
        get 'index', q: 'CD 1'
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).collect(&:id)). to eq [@media_object.id]
      end
      it 'should find results based upon section labels' do
        get 'index', q: 'Test Label'
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).collect(&:id)). to eq [@media_object.id]
      end
      it 'should find items in correct relevancy order' do
        media_object_1 = FactoryGirl.create(:fully_searchable_media_object, title: 'Test Label')
        get 'index', q: 'Test Label'
        expect(assigns(:document_list).count).to eq 2
        expect(assigns(:document_list).collect(&:id)).to eq [media_object_1.id, @media_object.id]
      end
    end

    describe "sort fields" do
      let!(:m1) { FactoryGirl.create(:published_media_object, title: 'Yabba', date_issued: '1960', creator: ['Fred'], visibility: 'public') }
      let!(:m2) { FactoryGirl.create(:published_media_object, title: 'Dabba', date_issued: '1970', creator: ['Betty'], visibility: 'public') }
      let!(:m3) { FactoryGirl.create(:published_media_object, title: 'Doo', date_issued: '1980', creator: ['Wilma'], visibility: 'public') }

      it "should sort correctly by title" do
        get :index, :sort => 'title_ssort asc, date_ssi desc'
        expect(assigns(:document_list).map(&:id)).to eq [m2.id, m3.id, m1.id]
      end
      it "should sort correctly by date" do
        get :index, :sort => 'date_ssi desc, title_ssort asc'
        expect(assigns(:document_list).map(&:id)).to eq [m3.id, m2.id, m1.id]
      end
      it "should sort correctly by creator" do
        get :index, :sort => 'creator_ssort asc, title_ssort asc'
        expect(assigns(:document_list).map(&:id)).to eq [m2.id, m1.id, m3.id]
      end
    end
  end
end
