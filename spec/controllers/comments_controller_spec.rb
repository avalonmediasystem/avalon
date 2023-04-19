# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

describe CommentsController do
  render_views

  let(:comment) { FactoryBot.build(:comment) }
  let(:comment_parameters) { comment.to_h.merge({ email_confirmation: comment.email }) } 

  describe '#create' do
    it 'sends a comment email' do
      post :create, params: { comment: comment_parameters }
      expect(response.status).to be 200
    end

    context 'missing parameters' do
      it 'shows error message' do
        post :create, params: { comment: { name: "Test" } }
        expect(response).to render_template(:index)
      end
    end

    context 'recaptcha enabled' do
      before do
        allow(Settings.recaptcha).to receive(:site_key).and_return("site_key")
        allow(Settings.recaptcha).to receive(:secret_key).and_return("secret_key")
        allow(Settings.recaptcha).to receive(:type).and_return(recaptcha_type)
        allow(Recaptcha.configuration).to receive(:site_key!).and_return("site_key")
        allow(Recaptcha.configuration).to receive(:secret_key!).and_return("secret_key")
      end

      context 'recaptcha v2' do
        let(:recaptcha_type) { "v2_checkbox" }

	it 'sends a comment email' do
          allow(controller).to receive(:verify_recaptcha)
	  post :create, params: { comment: comment_parameters }
	  expect(response.status).to be 200
          expect(controller).to have_received(:verify_recaptcha).with({ model: assigns(:comment) })
	end
      end

      context 'recaptcha v3' do
        let(:recaptcha_type) { "v3" }
        let(:action) { "comment" }
        let(:minimum_score) { 0.7 }

        before do
          allow(Settings.recaptcha.v3).to receive(:action).and_return(action)
          allow(Settings.recaptcha.v3).to receive(:minimum_score).and_return(minimum_score)
        end

	it 'sends a comment email' do
          allow(controller).to receive(:verify_recaptcha)
	  post :create, params: { comment: comment_parameters }
	  expect(response.status).to be 200
          expect(controller).to have_received(:verify_recaptcha).with({ action: action, minimum_score: minimum_score })
	end
      end
    end
  end
end
