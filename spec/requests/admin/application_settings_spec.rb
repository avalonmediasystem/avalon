require 'rails_helper'

RSpec.describe "Admin::ApplicationSettings", type: :request do
  describe "GET /show" do
    context "unauthenticated user" do
      it "renders the restricted content page" do
        get admin_application_settings_url
        expect(response).to render_template(:restricted_pid)
      end
    end

    context 'authenticated' do
      before { sign_in(user) }

      context 'regular user' do
        let(:user) { FactoryBot.create(:user) }

        it "renders the restricted content page" do
          get admin_application_settings_url
          expect(response).to render_template(:restricted_pid)
        end
      end

      context 'administrator' do
        let(:user) { FactoryBot.create(:administrator) }

        it "renders the show page" do
          get admin_application_settings_url
          expect(response).to render_template(:show)
        end
      end
    end
  end
end
