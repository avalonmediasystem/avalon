require 'rails_helper'

RSpec.describe CheckoutsController, type: :controller do

  describe 'GET #index' do
    before :each do
      FactoryBot.reload
      FactoryBot.create_list(:checkout, 2)
      FactoryBot.create(:checkout, return_time: DateTime.current - 2.weeks)
    end
    context 'as an admin user' do
      let(:admin) { FactoryBot.create(:admin) }
      before { sign_in admin }
      before { FactoryBot.create(:checkout, user: admin) }

      it 'returns all active checkouts' do
        get :index, params: {}
        expect(assigns(:checkouts).count).to eq(3)
      end
    end
    context 'as a regular user' do
      let(:user) { FactoryBot.create(:user) }
      before { sign_in user }
      before { FactoryBot.create(:checkout, user: user) }
      before { FactoryBot.create(:checkout, user: user, return_time: DateTime.current - 2.weeks) }

      it "returns the current user's active checkouts" do
        get :index, params: {}
        expect(assigns(:checkouts).count).to eq(1)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { FactoryBot.create(:user) }
    before { sign_in user }
    before { FactoryBot.create(:checkout, user: user) }
    before { FactoryBot.create(:checkout) }

    before { delete :destroy, params: { id: 1 } }

    it 'deletes the selected checkout' do
      expect{ Checkout.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(flash[:notice]).to match "was successfully destroyed."
    end
    it 'does not delete non-selected checkouts' do
      expect{ Checkout.find(2) }.not_to raise_error
    end
  end

  describe 'DELETE #return_all' do
    before :each do
      FactoryBot.reload
      FactoryBot.create_list(:checkout, 2)
    end
    context 'as a regular user' do
      let(:user1) { FactoryBot.create(:user) }
      before { sign_in user1 }
      before { FactoryBot.create(:checkout, user: user1) }
      
      it "deletes the current user's checkouts" do
        delete :return_all
        expect(Checkout.all.count).to eq(2)
      end
    end
    context 'as an admin user' do
      let(:admin) { FactoryBot.create(:admin) }
      before { sign_in admin }

      it 'deletes all checkouts' do
        delete :return_all
        expect(Checkout.all.count).to eq(0)
      end
    end
  end
end
