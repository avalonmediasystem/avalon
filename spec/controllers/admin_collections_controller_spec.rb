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

describe Admin::CollectionsController, type: :controller do
  render_views

  describe 'security' do
    let(:collection) { FactoryBot.create(:collection) }

    describe 'ingest api' do
      it "all routes should return 401 when no token is present" do
        expect(get :index, params: { format: 'json' }).to have_http_status(401)
        expect(get :show, params: { id: collection.id, format: 'json' }).to have_http_status(401)
        expect(get :items, params: { id: collection.id, format: 'json' }).to have_http_status(401)
        expect(post :create, params: { format: 'json' }).to have_http_status(401)
        expect(put :update, params: { id: collection.id, format: 'json' }).to have_http_status(401)
      end
      it "all routes should return 403 when a bad token in present" do
        request.headers['Avalon-Api-Key'] = 'badtoken'
        expect(get :index, params: { format: 'json' }).to have_http_status(403)
        expect(get :show, params: { id: collection.id, format: 'json' }).to have_http_status(403)
        expect(get :items, params: { id: collection.id, format: 'json' }).to have_http_status(403)
        expect(post :create, params: { format: 'json' }).to have_http_status(403)
        expect(put :update, params: { id: collection.id, format: 'json' }).to have_http_status(403)
      end
    end
    describe 'normal auth' do
      context 'with end-user' do
        before do
          login_as :user
        end
        # New is isolated here due to issues caused by the controller instance not being regenerated
        it "should redirect to restricted content page" do
          expect(get :new).to render_template('errors/restricted_pid')
        end
        it "all routes should redirect to restricted content page" do
          expect(get :index).to render_template('errors/restricted_pid')
          expect(get :show, params: { id: collection.id }).to render_template('errors/restricted_pid')
          expect(get :edit, params: { id: collection.id }).to render_template('errors/restricted_pid')
          expect(get :remove, params: { id: collection.id }).to render_template('errors/restricted_pid')
          expect(post :create).to render_template('errors/restricted_pid')
          expect(put :update, params: { id: collection.id }).to render_template('errors/restricted_pid')
          expect(patch :update, params: { id: collection.id }).to render_template('errors/restricted_pid')
          expect(delete :destroy, params: { id: collection.id }).to render_template('errors/restricted_pid')
          expect(post :attach_poster, params: { id: collection.id }).to render_template('errors/restricted_pid')
          expect(delete :remove_poster, params: { id: collection.id }).to render_template('errors/restricted_pid')
          expect(get :poster, params: { id: collection.id }).to render_template('errors/restricted_pid')
        end
      end
    end
  end

  describe "#manage" do
    let!(:collection) { FactoryBot.create(:collection) }
    before(:each) do
      request.env["HTTP_REFERER"] = '/'
      login_as(:administrator)
    end

    it "should add users to manager role" do
      manager = FactoryBot.create(:manager)
      put 'update', params: { id: collection.id, submit_add_manager: 'Add', add_manager: manager.user_key }
      collection.reload
      expect(manager).to be_in(collection.managers)
    end

    it "should not add users to manager role" do
      user = FactoryBot.create(:user)
      put 'update', params: { id: collection.id, submit_add_manager: 'Add', add_manager: user.user_key }
      collection.reload
      expect(user).not_to be_in(collection.managers)
      expect(flash[:error]).not_to be_empty
    end

    it "should remove users from manager role" do
      #initial_manager = FactoryBot.create(:manager).user_key
      collection.managers += [FactoryBot.create(:manager).user_key, FactoryBot.create(:manager).user_key]
      collection.save!
      manager = User.where(Devise.authentication_keys.first => collection.managers.first).first
      put 'update', params: { id: collection.id, remove_manager: manager.user_key }
      collection.reload
      expect(manager).not_to be_in(collection.managers)
    end

    context 'with zero-width characters' do
      let(:manager) { FactoryBot.create(:manager) }
      let(:manager_key) { "#{manager.user_key}\u200B" }

      it "should add users to manager role" do
        put 'update', params: { id: collection.id, submit_add_manager: 'Add', add_manager: manager_key }
        collection.reload
        expect(manager).to be_in(collection.managers)
      end
    end
  end

  describe "#edit" do
    let!(:collection) { FactoryBot.create(:collection) }
    before(:each) do
      request.env["HTTP_REFERER"] = '/'
    end

    it "should add users to editor role" do
      login_as(:administrator)
      editor = FactoryBot.build(:user)
      put 'update', params: { id: collection.id, submit_add_editor: 'Add', add_editor: editor.user_key }
      collection.reload
      expect(editor).to be_in(collection.editors)
    end

    it "should remove users from editor role" do
      login_as(:administrator)
      editor = User.where(Devise.authentication_keys.first => collection.editors.first).first
      put 'update', params: { id: collection.id, remove_editor: editor.user_key }
      collection.reload
      expect(editor).not_to be_in(collection.editors)
    end
  end

  describe "#deposit" do
    let!(:collection) { FactoryBot.create(:collection) }
    before(:each) do
      request.env["HTTP_REFERER"] = '/'
    end

    it "should add users to depositor role" do
      login_as(:administrator)
      depositor = FactoryBot.build(:user)
      put 'update', params: { id: collection.id, submit_add_depositor: 'Add', add_depositor: depositor.user_key }
      collection.reload
      expect(depositor).to be_in(collection.depositors)
    end

    it "should remove users from depositor role" do
      login_as(:administrator)
      depositor = User.where(Devise.authentication_keys.first => collection.depositors.first).first
      put 'update', params: { id: collection.id, remove_depositor: depositor.user_key }
      collection.reload
      expect(depositor).not_to be_in(collection.depositors)
    end
  end

  describe "#index" do
    let!(:collection) { FactoryBot.create(:collection) }
    subject(:json) { JSON.parse(response.body) }

    let(:administrator) { FactoryBot.create(:administrator) }

    before(:each) do
      ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
      request.headers['Avalon-Api-Key'] = 'secret_token'
    end
    it "should return list of collections" do
      get 'index', params: { format:'json' }
      expect(json.count).to eq(1)
      expect(json.first['id']).to eq(collection.id)
      expect(json.first['name']).to eq(collection.name)
      expect(json.first['unit']).to eq(collection.unit)
      expect(json.first['description']).to eq(collection.description)
      expect(json.first['object_count']['total']).to eq(collection.media_objects.count)
      expect(json.first['object_count']['published']).to eq(collection.media_objects.reject{|mo| !mo.published?}.count)
      expect(json.first['object_count']['unpublished']).to eq(collection.media_objects.reject{|mo| mo.published?}.count)
      expect(json.first['roles']['managers']).to eq(collection.managers)
      expect(json.first['roles']['editors']).to eq(collection.editors)
      expect(json.first['roles']['depositors']).to eq(collection.depositors)
    end
    it "should return list of collections for good user" do
      get 'index', params: { user: collection.managers.first, format:'json' }
      expect(json.count).to eq(1)
    end
    it "should return no collections for bad user" do
      get 'index', params: { user: 'foobar', format:'json' }
      expect(json.count).to eq(0)
    end
  end

  describe 'pagination' do
    subject(:json) { JSON.parse(response.body) }
    let(:administrator) { FactoryBot.create(:administrator) }

    before(:each) do
      ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
      request.headers['Avalon-Api-Key'] = 'secret_token'
    end
    it 'should paginate index' do
      5.times { FactoryBot.create(:collection) }
      get 'index', params: { format:'json', per_page: '2' }
      expect(json.count).to eq(2)
      expect(response.headers['Per-Page']).to eq('2')
      expect(response.headers['Total']).to eq('5')
    end
    it 'should paginate collection/items' do
      collection = FactoryBot.create(:collection, items: 5)
      get 'items', params: { id: collection.id, format: 'json', per_page: '2' }
      expect(json.count).to eq(2)
      expect(response.headers['Per-Page']).to eq('2')
      expect(response.headers['Total']).to eq('5')
    end
  end

  describe "#show" do
    let!(:collection) { FactoryBot.create(:collection) }

    it "should allow access to managers" do
      login_user(collection.managers.first)
      get 'show', params: { id: collection.id }
      expect(response).to be_ok
    end

    context "with json format" do
      subject(:json) { JSON.parse(response.body) }

      it "should return json for specific collection" do
        ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com'
        request.headers['Avalon-Api-Key'] = 'secret_token'
        get 'show', params: { id: collection.id, format:'json' }
        expect(json['id']).to eq(collection.id)
        expect(json['name']).to eq(collection.name)
        expect(json['unit']).to eq(collection.unit)
        expect(json['description']).to eq(collection.description)
        expect(json['object_count']['total']).to eq(collection.media_objects.count)
        expect(json['object_count']['published']).to eq(collection.media_objects.reject{|mo| !mo.published?}.count)
        expect(json['object_count']['unpublished']).to eq(collection.media_objects.reject{|mo| mo.published?}.count)
        expect(json['roles']['managers']).to eq(collection.managers)
        expect(json['roles']['editors']).to eq(collection.editors)
        expect(json['roles']['depositors']).to eq(collection.depositors)
      end

      it "should return 404 if requested collection not present" do
        ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com'
        request.headers['Avalon-Api-Key'] = 'secret_token'
        get 'show', params: { id: 'doesnt_exist', format: 'json' }
        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)["errors"].class).to eq Array
        expect(JSON.parse(response.body)["errors"].first.class).to eq String
      end
    end
  end

  describe "#items" do
    let!(:collection) { FactoryBot.create(:collection, items: 2) }
    let(:administrator) { FactoryBot.create(:administrator) }

    before(:each) do
      ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
      request.headers['Avalon-Api-Key'] = 'secret_token'
    end
    it "should return json for specific collection's media objects" do
      get 'items', params: { id: collection.id, format: 'json' }
      expect(JSON.parse(response.body)).to include(collection.media_objects[0].id,collection.media_objects[1].id)
      #TODO add check that mediaobject is serialized to json properly
    end

  end

  describe "#create" do
    let!(:collection) { FactoryBot.build(:collection) }
    let(:administrator) { FactoryBot.create(:administrator) }

    before(:each) do
      ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
      request.headers['Avalon-Api-Key'] = 'secret_token'
    end

    it "should notify administrators" do
      login_as(:administrator) #otherwise, there are no administrators to mail
      # mock_email = double('email')
      # allow(mock_email).to receive(:deliver_later)
      # expect(NotificationsMailer).to receive(:new_collection).and_return(mock_email)
      # FIXME: This delivers two instead of one for some reason
      expect {post 'create', params: { format:'json', admin_collection: {name: collection.name, description: collection.description, unit: collection.unit, managers: collection.managers} }}.to have_enqueued_job(ActionMailer::MailDeliveryJob).twice
      # post 'create', format:'json', admin_collection: {name: collection.name, description: collection.description, unit: collection.unit, managers: collection.managers}
    end
    it "should create a new collection" do
      post 'create', params: { format:'json', admin_collection: {name: collection.name, description: collection.description, unit: collection.unit, contact_email: collection.contact_email, website_label: collection.website_label, website_url: collection.website_url, managers: collection.managers} }
      expect(JSON.parse(response.body)['id'].class).to eq String
      expect(JSON.parse(response.body)).not_to include('errors')
      new_collection = Admin::Collection.find(JSON.parse(response.body)['id'])
      expect(new_collection.contact_email).to eq collection.contact_email
      expect(new_collection.website_label).to eq collection.website_label
      expect(new_collection.website_url).to eq collection.website_url
    end
    it "should create a new collection with default manager list containing current API user" do
      post 'create', params: { format:'json', admin_collection: { name: collection.name, description: collection.description, unit: collection.unit } }
      expect(JSON.parse(response.body)['id'].class).to eq String
      collection = Admin::Collection.find(JSON.parse(response.body)['id'])
      expect(collection.managers).to eq([administrator.username])
    end
    it "should return 422 if collection creation failed" do
      post 'create', params: { format:'json', admin_collection: { name: collection.name, description: collection.description } }
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)).to include('errors')
      expect(JSON.parse(response.body)["errors"].class).to eq Array
      expect(JSON.parse(response.body)["errors"].first.class).to eq String
    end

  end

  describe "#update" do
    it "should notify administrators if name changed" do
      login_as(:administrator) #otherwise, there are no administrators to mail
      # mock_delay = double('mock_delay').as_null_object
      # allow(NotificationsMailer).to receive(:deliver_later).and_return(mock_delay)
      # expect(mock_delay).to receive(:update_collection)
      @collection = FactoryBot.create(:collection)
      # put 'update', id: @collection.id, admin_collection: {name: "#{@collection.name}-new", description: @collection.description, unit: @collection.unit}
      expect {put 'update', params: { id: @collection.id, admin_collection: {name: "#{@collection.name}-new", description: @collection.description, unit: @collection.unit} }}.to have_enqueued_job(ActionMailer::MailDeliveryJob).once
    end

    context "update REST API" do
      let!(:collection) { FactoryBot.create(:collection)}
      let(:contact_email) { Faker::Internet.email }
      let(:website_label) { Faker::Lorem.words.join(' ') }
      let(:website_url) { Faker::Internet.url }

      before do
        ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com'
        request.headers['Avalon-Api-Key'] = 'secret_token'
      end

      it "should update a collection via API" do
        old_description = collection.description
        put 'update', params: { format: 'json', id: collection.id, admin_collection: { description: collection.description+'new', contact_email: contact_email, website_label: website_label, website_url: website_url }}
        expect(JSON.parse(response.body)['id'].class).to eq String
        expect(JSON.parse(response.body)).not_to include('errors')
        collection.reload
        expect(collection.description).to eq old_description+'new'
        expect(collection.contact_email).to eq contact_email
        expect(collection.website_label).to eq website_label
        expect(collection.website_url).to eq website_url
      end
      it "should return 422 if collection update via API failed" do
        allow_any_instance_of(Admin::Collection).to receive(:save).and_return false
        put 'update', params: { format: 'json', id: collection.id, admin_collection: {description: collection.description+'new'} }
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)).to include('errors')
        expect(JSON.parse(response.body)["errors"].class).to eq Array
        expect(JSON.parse(response.body)["errors"].first.class).to eq String
      end
    end
  end

  describe "#update_access" do
    let(:collection) { FactoryBot.create(:collection) }

    before do
      login_user(collection.managers.first)
    end

    context "should not allow empty" do
      it "user" do
        expect{ put 'update', params: { id: collection.id, submit_add_user: "Add", add_user: "", add_user_display: "" }}.not_to change{ collection.reload.default_read_users.size }
      end

      it "class" do
        expect{ put 'update', params: { id: collection.id, submit_add_class: "Add", add_class: "", add_class_display: "" }}.not_to change{ collection.reload.default_read_groups.size }
      end
    end

    context "add new special access" do
      it "user" do
        expect{ put 'update', params: { id: collection.id, submit_add_user: "Add", add_user: "test1@example.com", add_user_display: "test1" }}.to change{ collection.reload.default_read_users.size }.by(1)
      end

      it "group" do
        expect{ put 'update', params: { id: collection.id, submit_add_group: "Add", add_group: "test_group" }}.to change{ collection.reload.default_read_groups.size }.by(1)
      end

      it "external group" do
        expect{ put 'update', params: { id: collection.id, submit_add_class: "Add", add_class: "external", add_class_display: "external" }}.to change{ collection.reload.default_read_groups.size }.by(1)
      end

      it "IP address/range" do
        expect{ put 'update', params: { id: collection.id, submit_add_ipaddress: "Add", add_ipaddress: "255.0.0.1" }}.to change{ collection.reload.default_read_groups.size }.by(1)
      end
    end


    context "remove existing special access" do
      before do
        collection.default_read_users = ["test1@example.com"]
        collection.default_read_groups = ["test_group", "external_group", "255.0.1.1"]
        collection.save!
      end
      it "user" do
        expect{ put 'update', params: { id: collection.id, remove_user: "test1@example.com" }}.to change{ collection.reload.default_read_users.size }.by(-1)
      end

      it "group" do
        expect{ put 'update', params: { id: collection.id, remove_group: "test_group" }}.to change{ collection.reload.default_read_groups.size }.by(-1)
      end

      it "external group" do
        expect{ put 'update', params: { id: collection.id, remove_class: "external_group" }}.to change{ collection.reload.default_read_groups.size }.by(-1)
      end

      it "IP address/range" do
        expect{ put 'update', params: { id: collection.id, remove_ipaddress: "255.0.1.1" }}.to change{ collection.reload.default_read_groups.size }.by(-1)
      end
    end

    context "change default access control for item" do
      it "discovery" do
        put 'update', params: { id: collection.id, save_access: "Save Access Settings", hidden: "1" }
        collection.reload
        expect(collection.default_hidden).to be_truthy
      end

      it "access" do
        put 'update', params: { id: collection.id, save_access: "Save Access Settings", visibility: "public" }
        collection.reload
        expect(collection.default_visibility).to eq("public")
      end
    end

    context "changing lending period" do
      it "sets a custom lending period" do
        expect { put 'update', params: { id: collection.id, save_access: "Save Access Settings", add_lending_period_days: 7, add_lending_period_hours: 8 } }.to change { collection.reload.default_lending_period }.to(633600)
      end

      it "returns error if invalid" do
        expect { put 'update', params: { id: collection.id, save_access: "Save Access Settings", add_lending_period_days: -1, add_lending_period_hours: -1 } }.not_to change { collection.reload.default_lending_period }
        expect(response).to redirect_to(admin_collection_path(collection))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe "#apply_access" do
    let(:collection) { FactoryBot.create(:collection) }

    before do
      login_user(collection.managers.first)
    end

    context "replacing existing Special Access" do
      let(:overwrite) { true }
      it "enqueues a BulkActionJobs::ApplyCollectionAccessControl job" do
        expect { put 'update', params: { id: collection.id, apply_access: "Apply to All Existing Items", overwrite: overwrite } }.to have_enqueued_job(BulkActionJobs::ApplyCollectionAccessControl).with(collection.id, overwrite).once
      end
    end

    context "adding to existing Special Access" do
      let(:overwrite) { false }
      it "enqueues a BulkActionJobs::ApplyCollectionAccessControl job" do
        expect { put 'update', params: { id: collection.id, apply_access: "Apply to All Existing Items", overwrite: overwrite } }.to have_enqueued_job(BulkActionJobs::ApplyCollectionAccessControl).with(collection.id, overwrite).once
      end
    end
  end

  describe "#remove" do
    let!(:collection) { FactoryBot.create(:collection) }

    it "redirects to restricted content page when user does not have ability to delete collection" do
      login_as :user
      expect(controller.current_ability.can? :destroy, collection).to be_falsey
      expect(get :remove, params: { id: collection.id }).to render_template('errors/restricted_pid')
    end
    it "displays confirmation form for managers" do
      login_user collection.managers.first
      expect(controller.current_ability.can? :destroy, collection).to be_truthy
      expect(get :remove, params: { id: collection.id }).to render_template(:remove)
    end
  end

  describe '#attach_poster' do
    let(:collection) { FactoryBot.create(:collection) }

    before do
      login_user collection.managers.first
    end

    it 'adds the poster' do
      file = fixture_file_upload('/collection_poster.png', 'image/png')
      expect { post :attach_poster, params: { id: collection.id, admin_collection: { poster: file } } }.to change { collection.reload.poster.present? }.from(false).to(true)
      expect(collection.poster.mime_type).to eq 'image/png'
      expect(collection.poster.original_name).to eq 'collection_poster.png'
      expect(collection.poster.content).not_to be_blank
      expect(response).to redirect_to(admin_collection_path(collection))
      expect(flash[:success]).not_to be_empty
    end

    context 'with an invalid file' do

      it 'displays an error when the file is not an image' do
        file = fixture_file_upload('/captions.vtt', 'text/vtt')
        expect { post :attach_poster, params: { id: collection.id, admin_collection: { poster: file } } }.not_to change { collection.reload.poster.present? }
        expect(response).to redirect_to(admin_collection_path(collection))
        expect(flash[:error]).not_to be_empty
      end
    end

    context 'when saving fails' do
      before do
        allow_any_instance_of(Admin::Collection).to receive(:save).and_return(false)
      end

      it 'returns an error' do
        file = fixture_file_upload('/collection_poster.png', 'image/png')
        expect { post :attach_poster, params: { id: collection.id, admin_collection: { poster: file } } }.not_to change { collection.reload.poster.present? }
        expect(flash[:error]).not_to be_empty
        expect(response).to redirect_to(admin_collection_path(collection))
      end
    end
  end

  describe '#remove_poster' do
    let(:collection) { FactoryBot.create(:collection, :with_poster) }

    before do
      login_user collection.managers.first
    end

    it 'removes the poster' do
      expect { delete :remove_poster, params: { id: collection.id } }.to change { collection.reload.poster.present? }.from(true).to(false)
      expect(response).to redirect_to(admin_collection_path(collection))
      expect(flash[:success]).not_to be_empty
    end

    context 'when saving fails' do
      before do
        allow_any_instance_of(Admin::Collection).to receive(:save).and_return(false)
      end

      it 'returns an error' do
        expect { delete :remove_poster, params: { id: collection.id } }.not_to change { collection.reload.poster.present? }
        expect(response).to redirect_to(admin_collection_path(collection))
        expect(flash[:error]).not_to be_empty
      end
    end
  end

  describe '#poster' do
    let(:collection) { FactoryBot.create(:collection, :with_poster) }

    before do
      login_user collection.managers.first
    end

    it 'returns the poster' do
      get :poster, params: { id: collection.id }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq "image/png; charset=utf-8"
      expect(response.body).not_to be_blank
    end
  end
end
