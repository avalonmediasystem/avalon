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
    # before :each do
    #   FactoryBot.create_list(:user, 11)
    # end
    let(:user) {FactoryBot.create(:admin, username: 'aardvark', last_sign_in_at: Time.new)}
    before do
      sign_in(user)
      FactoryBot.create(:user, username: 'zzzebra', email: 'zzzebra@example.edu', last_sign_in_at: Time.new)
      FactoryBot.create_list(:user, 10, last_sign_in_at: Time.new)
    end

    context 'paging' do
      let(:common_params) { { order: { '0': { column: 0, dir: 'asc' } }, search: { value: '' } } }
      it 'returns all results' do
        post :paged_index, format: 'json', params: common_params.merge(start: 0, length: 20)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['recordsTotal']).to eq(12)
        expect(parsed_response['data'].count).to eq(12)
      end
      it 'returns first page' do
        post :paged_index, format: 'json', params: common_params.merge(start: 0, length: 10)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(10)
      end
      it 'returns second page' do
        post :paged_index, format: 'json', params: common_params.merge(start: 10, length: 10)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(2)
      end
    end

    context 'filtering' do
      let(:common_params) { { start: 0, length: 20, order: { '0': { column: 0, dir: 'asc' } } } }
      it "returns results filtered by username" do
        post :paged_index, format: 'json', params: common_params.merge(search: { value: user.username })
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['recordsFiltered']).to eq(1)
        expect(parsed_response['data'].count).to eq(1)
        expect(parsed_response['data'][0][0]).to eq("<a href=\"/persona/users/1/edit\">#{user.username}</a>")
      end
    end

    context 'filtering' do
      let(:common_params) { { start: 0, length: 20, order: { '0': { column: 1, dir: 'asc' } } } }
      it "returns results filtered by email" do
        post :paged_index, format: 'json', params: common_params.merge(search: { value: 'zzzebra@example.edu' })
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['recordsFiltered']).to eq(1)
        expect(parsed_response['data'].count).to eq(1)
        expect(parsed_response['data'][0][1]).to eq("<a href=\"/persona/users/2/edit\">zzzebra@example.edu</a>")
      end
    end

    context 'sorting' do
      let(:common_params) { { start: 0, length: 20, search: { value: '' } } }
      it "returns results sorted by username ascending" do
        post :paged_index, format: 'json', params: common_params.merge(order: { '0': { column: 0, dir: 'asc' } })
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'][0][0]).to eq("<a href=\"/persona/users/1/edit\">aardvark</a>")
        expect(parsed_response['data'][11][0]).to eq("<a href=\"/persona/users/2/edit\">zzzebra</a>")
      end

      it "returns results sorted by username descending" do
        post :paged_index, format: 'json', params: common_params.merge(order: { '0': { column: 0, dir: 'desc' } })
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'][0][0]).to eq("<a href=\"/persona/users/2/edit\">zzzebra</a>")
        expect(parsed_response['data'][11][0]).to eq("<a href=\"/persona/users/1/edit\">aardvark</a>")
      end
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
      before { delete :destroy, params: { id: user.to_param } }

      it "deletes the user and displays success message" do
        expect{ User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(flash[:notice]).to match "has been successfully deleted."
      end

      it "deletes the user without paranoia gem" do
        # expect{User.with_deleted.find(user.id)}.to_not raise_error
        expect(User.exists?(user.id)).to eq false
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
end
