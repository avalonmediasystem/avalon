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

describe Admin::UnitsController, type: :controller do
  render_views

  describe 'security' do
    let(:unit) { FactoryBot.create(:unit) }

    describe 'ingest api' do
      it "all routes should return 401 when no token is present" do
        expect(get :index, params: { format: 'json' }).to have_http_status(401)
        expect(get :show, params: { id: unit.id, format: 'json' }).to have_http_status(401)
        expect(get :items, params: { id: unit.id, format: 'json' }).to have_http_status(401)
        expect(post :create, params: { format: 'json' }).to have_http_status(401)
        expect(put :update, params: { id: unit.id, format: 'json' }).to have_http_status(401)
      end
      it "all routes should return 403 when a bad token in present" do
        request.headers['Avalon-Api-Key'] = 'badtoken'
        expect(get :index, params: { format: 'json' }).to have_http_status(403)
        expect(get :show, params: { id: unit.id, format: 'json' }).to have_http_status(403)
        expect(get :items, params: { id: unit.id, format: 'json' }).to have_http_status(403)
        expect(post :create, params: { format: 'json' }).to have_http_status(403)
        expect(put :update, params: { id: unit.id, format: 'json' }).to have_http_status(403)
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
          expect(get :show, params: { id: unit.id }).to render_template('errors/restricted_pid')
          expect(get :edit, params: { id: unit.id }).to render_template('errors/restricted_pid')
          expect(get :remove, params: { id: unit.id }).to render_template('errors/restricted_pid')
          expect(post :create).to render_template('errors/restricted_pid')
          expect(put :update, params: { id: unit.id }).to render_template('errors/restricted_pid')
          expect(patch :update, params: { id: unit.id }).to render_template('errors/restricted_pid')
          expect(delete :destroy, params: { id: unit.id }).to render_template('errors/restricted_pid')
          expect(post :attach_poster, params: { id: unit.id }).to render_template('errors/restricted_pid')
          expect(delete :remove_poster, params: { id: unit.id }).to render_template('errors/restricted_pid')
          expect(get :poster, params: { id: unit.id }).to render_template('errors/restricted_pid')
        end
      end
    end
  end

  describe "#manage" do
    let!(:unit) { FactoryBot.create(:unit) }
    before(:each) do
      request.env["HTTP_REFERER"] = '/'
      login_as(:administrator)
    end

    it "should add users to manager role" do
      manager = FactoryBot.create(:manager)
      put 'update', params: { id: unit.id, submit_add_manager: 'Add', add_manager: manager.user_key }
      unit.reload
      expect(manager).to be_in(unit.managers)
    end

    it "should not add users to manager role" do
      user = FactoryBot.create(:user)
      put 'update', params: { id: unit.id, submit_add_manager: 'Add', add_manager: user.user_key }
      unit.reload
      expect(user).not_to be_in(unit.managers)
      expect(flash[:error]).not_to be_empty
    end

    it "should remove users from manager role" do
      # initial_manager = FactoryBot.create(:manager).user_key
      unit.managers += [FactoryBot.create(:manager).user_key, FactoryBot.create(:manager).user_key]
      unit.save!
      manager = User.where(Devise.authentication_keys.first => unit.managers.first).first
      put 'update', params: { id: unit.id, remove_manager: manager.user_key }
      unit.reload
      expect(manager).not_to be_in(unit.managers)
    end

    context 'with zero-width characters' do
      let(:manager) { FactoryBot.create(:manager) }
      let(:manager_key) { "#{manager.user_key}\u200B" }

      it "should add users to manager role" do
        put 'update', params: { id: unit.id, submit_add_manager: 'Add', add_manager: manager_key }
        unit.reload
        expect(manager).to be_in(unit.managers)
      end
    end
  end

  describe "#edit" do
    let!(:unit) { FactoryBot.create(:unit) }
    before(:each) do
      request.env["HTTP_REFERER"] = '/'
    end

    it "should add users to editor role" do
      login_as(:administrator)
      editor = FactoryBot.build(:user)
      put 'update', params: { id: unit.id, submit_add_editor: 'Add', add_editor: editor.user_key }
      unit.reload
      expect(editor).to be_in(unit.editors)
    end

    it "should remove users from editor role" do
      login_as(:administrator)
      editor = User.where(Devise.authentication_keys.first => unit.editors.first).first
      put 'update', params: { id: unit.id, remove_editor: editor.user_key }
      unit.reload
      expect(editor).not_to be_in(unit.editors)
    end
  end

  describe "#deposit" do
    let!(:unit) { FactoryBot.create(:unit) }
    before(:each) do
      request.env["HTTP_REFERER"] = '/'
    end

    it "should add users to depositor role" do
      login_as(:administrator)
      depositor = FactoryBot.build(:user)
      put 'update', params: { id: unit.id, submit_add_depositor: 'Add', add_depositor: depositor.user_key }
      unit.reload
      expect(depositor).to be_in(unit.depositors)
    end

    it "should remove users from depositor role" do
      login_as(:administrator)
      depositor = User.where(Devise.authentication_keys.first => unit.depositors.first).first
      put 'update', params: { id: unit.id, remove_depositor: depositor.user_key }
      unit.reload
      expect(depositor).not_to be_in(unit.depositors)
    end
  end

  describe "#index" do
    let!(:unit) { FactoryBot.create(:unit, items: 1) }
    let!(:unit2) { FactoryBot.create(:unit, items: 1) }
    subject(:json) { JSON.parse(response.body) }

    let(:administrator) { FactoryBot.create(:administrator) }

    before(:each) do
      ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
      request.headers['Avalon-Api-Key'] = 'secret_token'
    end
    it "should return list of units" do
      get 'index', params: { format: 'json' }
      expect(json.count).to eq(2)
      expect(json.first['id']).to eq(unit.id)
      expect(json.first['name']).to eq(unit.name)
      expect(json.first['description']).to eq(unit.description)
      expect(json.first['object_count']['total']).to eq(unit.collections.count)
      expect(json.first['roles']['unit_admins']).to eq(unit.unit_admins)
      expect(json.first['roles']['managers']).to eq(unit.managers)
      expect(json.first['roles']['editors']).to eq(unit.editors)
      expect(json.first['roles']['depositors']).to eq(unit.depositors)
    end
    it "should return list of units for good user" do
      get 'index', params: { user: unit.managers.first, format: 'json' }
      expect(json.count).to eq(1)
    end
    it "should return no units for bad user" do
      get 'index', params: { user: 'foobar', format: 'json' }
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
      5.times { FactoryBot.create(:unit) }
      get 'index', params: { format: 'json', per_page: '2' }
      expect(json.count).to eq(2)
      expect(response.headers['Per-Page']).to eq('2')
      expect(response.headers['Total']).to eq('5')
    end
    it 'should paginate unit/items' do
      unit = FactoryBot.create(:unit, items: 5)
      get 'items', params: { id: unit.id, format: 'json', per_page: '2' }
      expect(json.count).to eq(2)
      expect(response.headers['Per-Page']).to eq('2')
      expect(response.headers['Total']).to eq('5')
    end
  end

  describe "#show" do
    let!(:unit) { FactoryBot.create(:unit) }

    it "should allow access to managers" do
      login_user(unit.managers.first)
      get 'show', params: { id: unit.id }
      expect(response).to be_ok
    end

    context "with json format" do
      subject(:json) { JSON.parse(response.body) }

      it "should return json for specific unit" do
        ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com'
        request.headers['Avalon-Api-Key'] = 'secret_token'
        get 'show', params: { id: unit.id, format: 'json' }
        expect(json['id']).to eq(unit.id)
        expect(json['name']).to eq(unit.name)
        expect(json['description']).to eq(unit.description)
        expect(json['object_count']['total']).to eq(unit.collections.count)
        expect(json['roles']['managers']).to eq(unit.managers)
        expect(json['roles']['editors']).to eq(unit.editors)
      end

      it "should return 404 if requested unit not present" do
        ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com'
        request.headers['Avalon-Api-Key'] = 'secret_token'
        get 'show', params: { id: 'doesnt_exist', format: 'json' }
        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)["errors"].class).to eq Array
        expect(JSON.parse(response.body)["errors"].first.class).to eq String
      end
    end

    context 'misformed NOID' do
      it 'should redirect to the requested unit' do
        get 'show', params: { id: "#{unit.id}] " }
        expect(response).to redirect_to(admin_unit_path(id: unit.id))
      end
      it 'should redirect to unknown_pid page if invalid' do
        get 'show', params: { id: "nonvalid noid]" }
        expect(response).to render_template("errors/unknown_pid")
        expect(response.response_code).to eq(404)
      end
    end
  end

  describe "#items" do
    let!(:unit) { FactoryBot.create(:unit, items: 2) }
    let(:administrator) { FactoryBot.create(:administrator) }

    before(:each) do
      ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
      request.headers['Avalon-Api-Key'] = 'secret_token'
    end
    it "should return json for specific unit's collections" do
      get 'items', params: { id: unit.id, format: 'json' }
      expect(JSON.parse(response.body)).to include(unit.collections[0].id, unit.collections[1].id)
      # TODO: add check that mediaobject is serialized to json properly
    end

    context 'user is a unit admin' do
      let(:unit_admin) { FactoryBot.create(:unit_admin) }
      before(:each) do
        ApiToken.create token: 'manager_token', username: unit_admin.username, email: unit_admin.email
        request.headers['Avalon-Api-Key'] = 'manager_token'
      end
      context 'user does not manage this unit' do
        it "should return a 401 response code" do
          get 'items', params: { id: unit.id, format: 'json' }
          expect(response.status).to eq(401)
        end
        it 'should not return json for specific unit\'s collections' do
          get 'items', params: { id: unit.id, format: 'json' }
          expect(response.body).to be_empty
        end
      end
      context 'user manages this unit' do
        let!(:unit) { FactoryBot.create(:unit, items: 2, unit_admins: [unit_admin.username]) }
        it "should not return a 401 response code" do
          get 'items', params: { id: unit.id, format: 'json' }
          expect(response.status).not_to eq(401)
        end
        it "should return json for specific unit's media objects" do
          get 'items', params: { id: unit.id, format: 'json' }
          expect(JSON.parse(response.body)).to include(unit.collections[0].id, unit.collections[1].id)
        end
      end
    end
  end

  describe "#create" do
    let!(:unit) { FactoryBot.build(:unit) }
    let(:administrator) { FactoryBot.create(:administrator) }

    before(:each) do
      ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
      request.headers['Avalon-Api-Key'] = 'secret_token'
    end

    it "should notify administrators" do
      login_as(:administrator) # otherwise, there are no administrators to mail
      # mock_email = double('email')
      # allow(mock_email).to receive(:deliver_later)
      # expect(NotificationsMailer).to receive(:new_unit).and_return(mock_email)
      # FIXME: This delivers two instead of one for some reason
      expect { post 'create', params: { format: 'json', admin_unit: { name: unit.name, description: unit.description, unit_admins: unit.unit_admins } } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).twice
      # post 'create', format:'json', admin_unit: {name: unit.name, description: unit.description, unit: unit.unit, managers: unit.managers}
    end
    it "should create a new unit" do
      post 'create', params: { format: 'json', admin_unit: { name: unit.name, description: unit.description, contact_email: unit.contact_email, website_label: unit.website_label, website_url: unit.website_url, unit_admins: unit.unit_admins } }
      expect(JSON.parse(response.body)['id'].class).to eq String
      expect(JSON.parse(response.body)).not_to include('errors')
      new_unit = Admin::Unit.find(JSON.parse(response.body)['id'])
      expect(new_unit.contact_email).to eq unit.contact_email
      expect(new_unit.website_label).to eq unit.website_label
      expect(new_unit.website_url).to eq unit.website_url
    end
    it "should create a new unit with default manager list containing current API user" do
      post 'create', params: { format: 'json', admin_unit: { name: unit.name, description: unit.description } }
      expect(JSON.parse(response.body)['id'].class).to eq String
      unit = Admin::Unit.find(JSON.parse(response.body)['id'])
      expect(unit.unit_admins).to eq([administrator.username])
    end
    it "should return 422 if unit creation failed" do
      post 'create', params: { format: 'json', admin_unit: { description: unit.description } }
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)).to include('errors')
      expect(JSON.parse(response.body)["errors"].class).to eq Array
      expect(JSON.parse(response.body)["errors"].first.class).to eq String
    end
  end

  describe "#update" do
    it "should notify administrators if name changed" do
      login_as(:administrator) # otherwise, there are no administrators to mail
      # mock_delay = double('mock_delay').as_null_object
      # allow(NotificationsMailer).to receive(:deliver_later).and_return(mock_delay)
      # expect(mock_delay).to receive(:update_unit)
      @unit = FactoryBot.create(:unit)
      # put 'update', id: @unit.id, admin_unit: {name: "#{@unit.name}-new", description: @unit.description, unit: @unit.unit}
      expect { put 'update', params: { id: @unit.id, admin_unit: { name: "#{@unit.name}-new", description: @unit.description } } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).once
    end

    context "update REST API" do
      let!(:unit) { FactoryBot.create(:unit) }
      let(:contact_email) { Faker::Internet.email }
      let(:website_label) { Faker::Lorem.words.join(' ') }
      let(:website_url) { Faker::Internet.url }

      before do
        ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com'
        request.headers['Avalon-Api-Key'] = 'secret_token'
      end

      it "should update a unit via API" do
        old_description = unit.description
        put 'update', params: { format: 'json', id: unit.id, admin_unit: { description: unit.description + 'new', contact_email: contact_email, website_label: website_label, website_url: website_url } }
        expect(JSON.parse(response.body)['id'].class).to eq String
        expect(JSON.parse(response.body)).not_to include('errors')
        unit.reload
        expect(unit.description).to eq old_description + 'new'
        expect(unit.contact_email).to eq contact_email
        expect(unit.website_label).to eq website_label
        expect(unit.website_url).to eq website_url
      end
      it "should return 422 if unit update via API failed" do
        allow_any_instance_of(Admin::Unit).to receive(:save).and_return false
        put 'update', params: { format: 'json', id: unit.id, admin_unit: { description: unit.description + 'new' } }
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)).to include('errors')
        expect(JSON.parse(response.body)["errors"].class).to eq Array
        expect(JSON.parse(response.body)["errors"].first.class).to eq String
      end
    end
  end

  describe "#update_access" do
    let(:unit) { FactoryBot.create(:unit) }

    before do
      login_user(unit.unit_admins.first)
    end

    context "should not allow empty" do
      it "user" do
        expect { put 'update', params: { id: unit.id, submit_add_user: "Add", add_user: "", add_user_display: "" } }.not_to change { unit.reload.default_read_users.size }
      end

      it "class" do
        expect { put 'update', params: { id: unit.id, submit_add_class: "Add", add_class: "", add_class_display: "" } }.not_to change { unit.reload.default_read_groups.size }
      end
    end

    context "add new special access" do
      it "user" do
        expect { put 'update', params: { id: unit.id, submit_add_user: "Add", add_user: "test1@example.com", add_user_display: "test1" } }.to change { unit.reload.default_read_users.size }.by(1)
      end

      it "group" do
        expect { put 'update', params: { id: unit.id, submit_add_group: "Add", add_group: "test_group" } }.to change { unit.reload.default_read_groups.size }.by(1)
      end

      it "external group" do
        expect { put 'update', params: { id: unit.id, submit_add_class: "Add", add_class: "external", add_class_display: "external" } }.to change { unit.reload.default_read_groups.size }.by(1)
      end

      it "IP address/range" do
        expect { put 'update', params: { id: unit.id, submit_add_ipaddress: "Add", add_ipaddress: "255.0.0.1" } }.to change { unit.reload.default_read_groups.size }.by(1)
      end
    end

    context "remove existing special access" do
      before do
        unit.default_read_users = ["test1@example.com"]
        unit.default_read_groups = ["test_group", "external_group", "255.0.1.1"]
        unit.save!
      end
      it "user" do
        expect { put 'update', params: { id: unit.id, remove_user: "test1@example.com" } }.to change { unit.reload.default_read_users.size }.by(-1)
      end

      it "group" do
        expect { put 'update', params: { id: unit.id, remove_group: "test_group" } }.to change { unit.reload.default_read_groups.size }.by(-1)
      end

      it "external group" do
        expect { put 'update', params: { id: unit.id, remove_class: "external_group" } }.to change { unit.reload.default_read_groups.size }.by(-1)
      end

      it "IP address/range" do
        expect { put 'update', params: { id: unit.id, remove_ipaddress: "255.0.1.1" } }.to change { unit.reload.default_read_groups.size }.by(-1)
      end
    end

    context "change default access control for item" do
      it "discovery" do
        put 'update', params: { id: unit.id, save_field: "discovery", hidden: "1" }
        unit.reload
        expect(unit.default_hidden).to be_truthy
      end

      it "access" do
        put 'update', params: { id: unit.id, save_field: "visibility", visibility: "public" }
        unit.reload
        expect(unit.default_visibility).to eq("public")
      end
    end
  end

  describe "#remove" do
    let!(:unit) { FactoryBot.create(:unit) }

    it "redirects to restricted content page when user does not have ability to delete unit" do
      login_as :user
      expect(controller.current_ability.can? :destroy, unit).to be_falsey
      expect(get :remove, params: { id: unit.id }).to render_template('errors/restricted_pid')
    end
    it "displays confirmation form for managers" do
      login_user unit.unit_admins.first
      expect(controller.current_ability.can? :destroy, unit).to be_truthy
      expect(get :remove, params: { id: unit.id }).to render_template(:remove)
    end
  end

  describe '#attach_poster' do
    let(:unit) { FactoryBot.create(:unit) }

    before do
      login_user unit.managers.first
    end

    it 'adds the poster' do
      file = fixture_file_upload('/collection_poster.png', 'image/png')
      expect { post :attach_poster, params: { id: unit.id, admin_unit: { poster: file } } }.to change { unit.reload.poster.present? }.from(false).to(true)
      expect(unit.poster.mime_type).to eq 'image/png'
      expect(unit.poster.original_name).to eq 'collection_poster.png'
      expect(unit.poster.content).not_to be_blank
      expect(response).to redirect_to(admin_unit_path(unit))
      expect(flash[:success]).not_to be_empty
    end

    context 'with an invalid file' do
      it 'displays an error when the file is not an image' do
        file = fixture_file_upload('/captions.vtt', 'text/vtt')
        expect { post :attach_poster, params: { id: unit.id, admin_unit: { poster: file } } }.not_to change { unit.reload.poster.present? }
        expect(response).to redirect_to(admin_unit_path(unit))
        expect(flash[:error]).not_to be_empty
      end
    end

    context 'with a UTF8 filename' do
      it 'adds the poster and displays as UTF8' do
        file = fixture_file_upload('/きた!.png', 'image/png')
        expect { post :attach_poster, params: { id: unit.id, admin_unit: { poster: file } } }.to change { unit.reload.poster.present? }.from(false).to(true)
        expect(unit.poster.mime_type).to eq 'image/png'
        expect(unit.poster.original_name).to eq 'きた!.png'
        expect(unit.poster.original_name.encoding.name).to eq 'UTF-8'
        expect(unit.poster.content).not_to be_blank
        expect(response).to redirect_to(admin_unit_path(unit))
        expect(flash[:success]).not_to be_empty
      end
    end

    context 'when saving fails' do
      before do
        allow_any_instance_of(Admin::Unit).to receive(:save).and_return(false)
      end

      it 'returns an error' do
        file = fixture_file_upload('/collection_poster.png', 'image/png')
        expect { post :attach_poster, params: { id: unit.id, admin_unit: { poster: file } } }.not_to change { unit.reload.poster.present? }
        expect(flash[:error]).not_to be_empty
        expect(response).to redirect_to(admin_unit_path(unit))
      end
    end
  end

  describe '#remove_poster' do
    let(:unit) { FactoryBot.create(:unit, :with_poster) }

    before do
      login_user unit.managers.first
    end

    it 'removes the poster' do
      expect { delete :remove_poster, params: { id: unit.id } }.to change { unit.reload.poster.present? }.from(true).to(false)
      expect(response).to redirect_to(admin_unit_path(unit))
      expect(flash[:success]).not_to be_empty
    end

    context 'when saving fails' do
      before do
        allow_any_instance_of(Admin::Unit).to receive(:save).and_return(false)
      end

      it 'returns an error' do
        expect { delete :remove_poster, params: { id: unit.id } }.not_to change { unit.reload.poster.present? }
        expect(response).to redirect_to(admin_unit_path(unit))
        expect(flash[:error]).not_to be_empty
      end
    end
  end

  describe '#poster' do
    let(:unit) { FactoryBot.create(:unit, :with_poster) }

    before do
      login_user unit.unit_admins.first
    end

    it 'returns the poster' do
      get :poster, params: { id: unit.id }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq "image/png; charset=utf-8"
      expect(response.body).not_to be_blank
    end

    context 'read from solr' do
      it 'should not read from fedora' do
        WebMock.reset_executed_requests!
        get :poster, params: { id: unit.id }
        expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
      end
    end
  end
end
