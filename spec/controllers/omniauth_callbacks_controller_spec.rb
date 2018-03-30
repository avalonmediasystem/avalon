# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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
    context 'when url param is present' do
      let(:user) { FactoryGirl.create(:user) }
      let(:params) {{ url: "http://other.host.com/a/sub/page" }}

      before do
        allow(User).to receive(:find_for_identity).and_return(user)
      end

      it 'redirects to homepage if url host does not match app host' do
        post :identity, params
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
