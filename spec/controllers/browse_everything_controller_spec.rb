# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

RSpec.describe BrowseEverythingController, type: :controller do

  routes { BrowseEverything::Engine.routes }

  let(:user) { FactoryBot.create(:user) }

  describe 'security' do
    context 'with unauthenticated user' do
      it 'returns 401 unauthorized' do
        expect(get :index).to be_unauthorized
        expect(get :index, xhr: true).to be_unauthorized
        expect(get :show, params: { provider: 'file_system' }).to be_unauthorized
        expect(get :show, params: { provider: 'file_system' }, xhr: true).to be_unauthorized
        expect(get :show, params: { provider: 'file_system', context: 'abcd1234' }, xhr: true).to be_unauthorized
        expect(get :show, params: { provider: 'file_system', context: 'abcd1234', path: 'subfolder' }, xhr: true).to be_unauthorized
        expect(get :auth).to be_unauthorized
        expect(get :auth, xhr: true).to be_unauthorized
        expect(get :resolve).to be_unauthorized
        expect(get :resolve, xhr: true).to be_unauthorized
      end
    end

    context 'with end-user' do
      before { login_user user.user_key }

      it 'returns 401 unauthorized' do
        expect(get :index).to be_unauthorized
        expect(get :index, xhr: true).to be_unauthorized
        expect(get :show, params: { provider: 'file_system' }).to be_unauthorized
        expect(get :show, params: { provider: 'file_system' }, xhr: true).to be_unauthorized
        expect(get :show, params: { provider: 'file_system', context: 'abcd1234' }, xhr: true).to be_unauthorized
        expect(get :show, params: { provider: 'file_system', context: 'abcd1234', path: 'subfolder' }, xhr: true).to be_unauthorized
        expect(get :auth).to be_unauthorized
        expect(get :auth, xhr: true).to be_unauthorized
        expect(get :resolve).to be_unauthorized
        expect(get :resolve, xhr: true).to be_unauthorized
      end
    end

    context 'with collection memeber' do
      let!(:collection) { FactoryBot.create(:collection, depositors: [user.to_s]) }

      before { login_user user.user_key }

      it 'responds' do
        expect(get :index).to be_successful
        expect(get :index, xhr: true).to be_successful
        #expect(get :show, params: { provider: 'file_system' }).to be_successful # raises ActionView::MissingTemplate
        expect(get :show, params: { provider: 'file_system' }, xhr: true).to be_successful
        expect(get :show, params: { provider: 'file_system', context: collection.id}, xhr: true).to be_successful
        expect(get :show, params: { provider: 'file_system', context: collection.id, path: 'subfolder' }, xhr: true).to be_successful
        expect(get :auth).to be_successful
        expect(get :auth, xhr: true).to be_successful
        #expect(get :resolve).to be_successful # raises ActionView::MissingTemplate
        expect(get :resolve, format: :json, xhr: true).to be_successful
      end
    end
  end
end
