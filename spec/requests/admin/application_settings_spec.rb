require 'rails_helper'

RSpec.describe "/admin/application_settings", type: :request, skip_stubbing: true do
  let(:admin) { FactoryBot.create(:administrator) }

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
        let(:user) { admin }
        let(:payload) { { name: 'Test' } }

        it 'renders the show page for all routes' do
          get admin_application_settings_url
          expect(response).to render_template(:show)
          patch admin_application_settings_url, params: { admin_application_setting: payload }
          expect(response).to redirect_to("/admin/application_settings")
          expect(response).to have_http_status(302)
          follow_redirect!
          expect(response).to render_template(:show)
          put admin_application_settings_url, params: { admin_application_setting: payload }
          expect(response).to redirect_to("/admin/application_settings")
          expect(response).to have_http_status(302)
          follow_redirect!
          expect(response).to render_template(:show)
        end
      end
    end
  end

  describe "GET /show" do
    before { sign_in(admin) }

    it "renders the show page" do
      get admin_application_settings_url
      expect(response).to render_template(:show)
    end
  end

  describe "PATCH /update" do
    let(:settings) { Admin::ApplicationSetting.instance }
    before { sign_in(admin) }

    context 'top level settings' do
      let(:payload) { { name: 'Test', repository_read_only_mode: true } }

      it "successfully updates" do
        expect {
          patch admin_application_settings_url, params: { admin_application_setting: payload }
          settings.reload
        }.to change { settings.name }.from('Avalon Media System').to('Test')
         .and change { settings.repository_read_only_mode }.from(false).to(true)
      end
    end

    context 'nested settings' do
      let(:payload) { { email_attributes: { mailer: 'aws', config: { address: 'http://local.test' } } } }
      it "successfully updates" do
        expect do
          patch admin_application_settings_url, params: { admin_application_setting: payload }
          settings.reload
        end.to change { settings.email.mailer }.from('smtp').to('aws')
           .and change { settings.email.config.address }.from('mail-relay.iu.edu').to('http://local.test')
      end
    end
  end
end
