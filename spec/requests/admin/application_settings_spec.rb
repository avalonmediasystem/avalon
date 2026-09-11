require 'rails_helper'

RSpec.describe "/admin/application_settings", type: :request do
  describe 'security' do
    context 'unauthenticated user' do
      it 'renders the restricted content page for all routes' do
        get admin_application_settings_url
        expect(response).to render_template(:restricted_pid)
        patch admin_application_settings_url
        expect(response).to render_template(:restricted_pid)
        put admin_application_settings_url
        expect(response).to render_template(:restricted_pid)
      end
    end

    context 'authenticated' do
      before { sign_in(user) }
      context 'regular user' do
        let(:user) { FactoryBot.create(:user) }

        it 'renders the restricted content page for all routes' do
          get admin_application_settings_url
          expect(response).to render_template(:restricted_pid)
          patch admin_application_settings_url
          expect(response).to render_template(:restricted_pid)
          put admin_application_settings_url
          expect(response).to render_template(:restricted_pid)
        end
      end

      context 'admin user' do
        let(:user) { FactoryBot.create(:administrator) }
        let(:settings) { Admin::ApplicationSetting.instance }

        before do
          settings.name = "Test"
          @settings = JSON.parse(settings.options_before_type_cast).transform_keys do |key|
            settings[key].is_a?(Hash) ? "#{key}_attributes" : key
          end.deep_symbolize_keys
        end

        it 'renders the show page for all routes' do
          get admin_application_settings_url
          expect(response).to render_template(:show)
          patch admin_application_settings_url, params: { admin_application_setting: @settings }
          expect(response).to redirect_to("/admin/application_settings")
          expect(response).to have_http_status(302)
          # follow_redirect!
          # expect(response).to render_template(:show)
          # put admin_application_settings_url, params: { admin_application_setting: @settings }
          # expect(response).to redirect_to("/admin/application_settings")
          # expect(response).to have_http_status(302)
          # follow_redirect!
          # expect(response).to render_template(:show)
        end
      end
    end
  end

  describe "GET /show" do
    before { sign_in(FactoryBot.create(:administrator)) }

    it "renders the show page" do
      get admin_application_settings_url
      expect(response).to render_template(:show)
    end
  end

  describe 'PATCH /update' do
    before { sign_in(FactoryBot.create(:administrator)) }
  end
end
