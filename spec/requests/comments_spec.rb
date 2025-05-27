# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

  describe "GET /index" do
    before { get comments_url }
    it 'renders a successful response' do
      expect(response).to be_successful
    end
    it 'renders the index partial' do
      expect(response).to render_template(:index)
    end
  end

  describe "POST /create" do
    let(:email) { Faker::Internet.email }
    let(:attributes) {
      { comment:
        { name: Faker::Name.name,
          subject: 'General feedback',
          email: email,
          email_confirmation: email,
          nickname: '',
          comment: Faker::Lorem.sentence
        }
      }
    }
    context 'all fields have been properly filled in' do
      it 'renders a successful response' do
        post comments_url, params: attributes
        expect(response).to be_successful
      end
      it 'queues the comment email for delivery' do
        post comments_url, params: attributes
        assert_enqueued_jobs(1)
      end
      it 'produces an email with proper contents' do
        expect { post comments_url, params: attributes }.to(
          have_enqueued_mail(CommentsMailer, :contact_email).with(
            name: attributes[:comment][:name], subject: attributes[:comment][:subject],
            email: email, nickname: '', comment: attributes[:comment][:comment]
          )
        )
      end
    end
    context 'not all fields have been filled in' do
      before { attributes[:comment][:comment] = nil }
      it 'does not queue an email for delivery' do
        post comments_url, params: attributes
        assert_enqueued_jobs(0)
      end
      it 'returns a flash message informing the user that information is missing' do
        post comments_url, params: attributes
        expect(flash[:error]).to eq('Your comment was missing required information. Please complete all fields and resubmit.')
      end
      it 'renders the index partial' do
        post comments_url, params: attributes
        expect(response).to render_template(:index)
      end
    end
    context 'the connection is interrupted' do
      it 'returns a flash message asking the user to report the problem' do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later).and_raise(Errno::ECONNRESET)
        post comments_url, params:attributes
        expect(flash[:notice]).to eq("The message could not be sent in a timely fashion. Contact us at #{Settings.email.support} to report the problem.")
      end
      it 'does not enqueue an email for delivery' do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later).and_raise(Errno::ECONNRESET)
        post comments_url, params:attributes
        assert_enqueued_jobs(0)
      end
      it 'renders the index partial' do
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later).and_raise(Errno::ECONNRESET)
        post comments_url, params:attributes
        expect(response).to render_template(:index)
      end
    end
  end
end
