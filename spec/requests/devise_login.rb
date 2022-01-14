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

describe 'devise login', type: :request do
  describe 'post-login redirect' do
    let(:user) { FactoryBot.create(:user) }

    it 'redirects to home page' do
      post '/users/sign_in', params: { user: { login: user.username, password: user.password }, admin: true, email: true }
      expect(response).to redirect_to(root_path)
    end

    it 'redirects to home page even when last request was not the home page' do
      get '/collections.json', params: { limit: 10, only: 'carousel' }
      post '/users/sign_in', params: { user: { login: user.username, password: user.password }, admin: true, email: true }
      expect(response).to redirect_to(root_path)
    end

    context 'when previous_url is in the session' do
      let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'restricted') }

      it 'redirects to url' do
        get "/media_objects/#{media_object.id}"
        post '/users/sign_in', params: { user: { login: user.username, password: user.password }, admin: true, email: true }
        expect(response).to redirect_to("/media_objects/#{media_object.id}")
      end
    end
  end
end
