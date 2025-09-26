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

RSpec.describe Samvera::Persona::UsersController, type: :controller do
  describe "#index" do
    let(:user) {FactoryBot.create(:admin)}
    before do
      sign_in(user)
    end

    it "is successful" do
      get :index
      expect(response).to be_successful
      expect(assigns[:presenter]).to be_kind_of Samvera::Persona::UsersPresenter
    end
  end

  describe "POST #paged_index" do
    let(:user) {FactoryBot.create(:admin, username: 'aardvark', last_sign_in_at: Time.new(2022,05,15))}
    before do
      sign_in(user)
      FactoryBot.create(:user, username: 'zzzebra', email: 'zzzebra@example.edu', last_sign_in_at: Time.new(2022,05,26), invitation_token: 'invited')
      FactoryBot.create_list(:user, 10, last_sign_in_at: Time.new(2022,05,24))
    end

    it 'returns all results' do
      post :paged_index, format: 'json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['recordsTotal']).to eq(12)
      expect(parsed_response['data'].count).to eq(12)
    end
  end

  context 'as an anonymous user' do
    let(:user) { FactoryBot.create(:user) }

    describe 'DELETE #destroy' do
      subject { User.find_by(id: user.id) }

      before { delete :destroy, params: { id: user.id } }

      it "doesn't delete the user and redirects to login" do
        expect(subject).not_to be_nil
        expect(response).to redirect_to controller.main_app.new_user_session_path
      end
    end
  end

  context 'as an admin user' do
    let(:user) { FactoryBot.create(:admin) }
    before { sign_in user }

    describe 'DELETE #destroy' do
      before :each do
        new_hash = {"administrator"=>[user.username], "group_manager"=>[user.username, "alice.archivist@example.edu"], "registered"=>["bob.user@example.edu"]}
        RoleMap.replace_with!(new_hash)
      end
      before { delete :destroy, params: { id: user.to_param } }

      it "deletes the user and displays success message" do
        expect{ User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(flash[:notice]).to match "has been successfully deleted."
      end

      it "deletes the user without paranoia gem" do
        # expect{User.with_deleted.find(user.id)}.to_not raise_error
        expect(User.exists?(user.id)).to eq false
      end

      it "removes the user from groups" do
        expect(RoleMap.all.find_by(entry: user.username)).to be_nil
      end

      it "doesn't remove other users from groups" do
        expect(RoleMap.all.find_by(entry: 'alice.archivist@example.edu').entry).to eq 'alice.archivist@example.edu'
        expect(RoleMap.all.find_by(entry: 'bob.user@example.edu').entry).to eq 'bob.user@example.edu'
      end
    end
  end

  context 'pretender' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:ldap_groups) { [] }
    before do
      sign_in admin
      allow(current_user).to receive(:ldap_groups).and_return(ldap_groups)
    end

    describe 'POST #impersonate' do
      let(:current_user) { FactoryBot.create(:user) }

      it 'allows you to impersonate another user' do
        post :impersonate, params: { id: current_user.id }
        expect(response).to redirect_to(controller.main_app.root_path)
      end

      context 'with external groups' do
        let(:ldap_groups) { ['ldap_group1', 'ldap_group2'] }

        before do
          allow(User).to receive(:find).with(current_user.to_param).and_return(current_user)
        end

        it 'sets the virtual groups for the new user' do
          expect { post :impersonate, params: { id: current_user.id }}.to change { @controller.user_session[:virtual_groups] }.from(nil).to(ldap_groups)
        end
      end
    end

    describe 'POST #stop_impersonating' do
      let(:current_user) { FactoryBot.create(:user) }

      it 'allows you to stop impersonating' do
        post :stop_impersonating, params: { id: current_user.id }
        expect(response).to redirect_to(controller.main_app.persona_users_path)
      end

      context 'with external groups' do
        let(:old_ldap_groups) { ['ldap_group1', 'ldap_group2'] }

        before do
          @controller.user_session[:virtual_groups] = old_ldap_groups
        end

        it 'sets the virtual groups for the new user' do
          expect { post :stop_impersonating, params: { id: current_user.id }}.to change { @controller.user_session[:virtual_groups] }.from(old_ldap_groups).to([])
        end
      end
    end
  end

  describe "#update" do
    let(:user) { FactoryBot.create(:user) }
    let(:admin) { FactoryBot.create(:admin) }

    before do
      sign_in(admin)
    end

    it 'updates email' do
      expect { put :update, params: { id: user.id, user: { username: user.username, email: "new_email@example.com" } } }.to change { user.reload.email }.to("new_email@example.com")
    end
  end
end
