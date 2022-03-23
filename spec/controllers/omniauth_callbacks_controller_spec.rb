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

describe Users::OmniauthCallbacksController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#find_user' do
    let(:user) { FactoryBot.create(:user) }

    before do
      allow(User).to receive(:find_for_identity).and_return(user)
    end

    it 'redirects to homepage' do
      post :identity
      expect(response).to redirect_to(root_path)
    end

    context 'when url param is present' do
      let(:params) {{ url:  url }}
      let(:url) { "http://test.host/a/sub/page?test_param=true" }

      it 'redirects to url without params' do
        post :identity, params: params
        expect(response).to redirect_to(Addressable::URI.parse(url).path)
      end

      context "and does not match app host" do
        let(:url) { "http://other.host.com/a/sub/page" }

        it 'redirects to homepage' do
          post :identity, params: params
          expect(response).to redirect_to(root_path)
        end
      end
    end

    context 'when login_popup param is present' do
      let(:params) {{ login_popup: 1 }}
      let(:self_closing_html) { '<html><head><script>window.close();</script></head><body></body><html>' }

      it 'returns self-closing page' do
        post :identity, params: params
        expect(response.content_type).to eq 'text/html; charset=utf-8'
        expect(response.body).to eq self_closing_html
      end
    end

    context 'when target_id param is present' do
      let(:params) {{ target_id: target_id }}
      let(:target_id) { 'abc1234' }

      it 'redirects to objects controller with id' do
        post :identity, params: params
        expect(response).to redirect_to(objects_path(target_id))
      end

      context 'with additional context parameters' do
        let(:additional_params) {{ t: '1234', position: '2', token: 'ABCDE12345' }}
        let(:params) { { target_id: target_id }.merge(additional_params) }

        it 'redirects to objects controller with id and context parameters' do
          post :identity, params: params
          expect(response).to redirect_to(objects_path(target_id, additional_params))
        end

        context 'including non-whitelisted params' do
          let(:unknown_param) {{ unknown_params: 'SCARY' }}
          let(:params) { { target_id: target_id }.merge(additional_params).merge(unknown_param) }

          it 'strips the unknown params' do
            post :identity, params: params
            expect(response).to redirect_to(objects_path(target_id, additional_params))
          end
        end
      end
    end

    context 'when previous_url is in the session' do
      let(:previous_url) { "http://test.host/a/sub/page?test_param=true" }

      it 'redirects to url' do
        post :identity, session: { previous_url: previous_url }
        expect(response).to redirect_to(previous_url)
      end
    end

    context 'when lti login with course group' do
      let(:course_group) { 'M101-Fall2019' }
      let(:lti_auth_double) { double() }
      let(:lti_extra_info) { double() }

      before do
        allow(User).to receive(:find_for_lti).and_return(user)
        @request.env["omniauth.auth"] = lti_auth_double
        allow(lti_auth_double).to receive(:extra).and_return (lti_extra_info)
        allow(lti_extra_info).to receive(:context_id).and_return (course_group)
      end

      it 'redirects to search with external group facet applied' do
        post :lti, session: { lti_group: course_group }
        expect(response).to redirect_to(search_catalog_path('f[read_access_virtual_group_ssim][]' => course_group))
      end
    end

    context 'when lti with deleted user' do
      let(:course_group) { 'M101-Fall2019' }
      let(:lti_auth_double) { double() }
      let(:lti_extra_info) { double() }

      before do
        allow(User).to receive(:find_for_lti).and_raise(Avalon::DeletedUserId)
        @request.env["omniauth.auth"] = lti_auth_double
        allow(lti_auth_double).to receive(:extra).and_return (lti_extra_info)
        allow(lti_extra_info).to receive(:context_id).and_return (course_group)
      end

      it 'redirects to root path' do
        post :lti, session: { lti_group: course_group }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
