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

describe 'CommentsMailer' do

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe 'contact_email' do
    let(:email) { Faker::Internet.email }
    let(:comment) {
        {
          name: Faker::Name.name,
          subject: 'General feedback',
          email: email,
          email_confirmation: email,
          nickname: '',
          comment: Faker::Lorem.sentence
        }
      }

    let(:mail) { CommentsMailer.contact_email(comment.to_h) }

    it 'has correct e-mail address' do
      expect(mail).to deliver_to(Settings.email.comments)
    end

    it 'has correct subject' do
      expect(mail).to have_subject("#{Settings.name}: #{comment[:subject]}")
    end

    context 'body' do
      it 'has commenter\'s information' do
        expect(mail).to have_body_text(comment[:name])
        expect(mail).to have_body_text(comment[:email])
      end
      it 'has instance information' do
        expect(mail).to have_body_text(Settings.name)
      end
      it 'has the subject' do
        expect(mail).to have_body_text(comment[:subject])
      end
      it 'has the comment' do
        expect(mail).to have_body_text(comment[:comment])
      end
      it 'has the date received' do
        expect(mail).to have_body_text(DateTime.now.to_s)
      end
    end
  end
end
