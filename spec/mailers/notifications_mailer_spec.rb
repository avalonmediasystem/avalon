# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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


describe 'NotificationsMailer' do

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe '#update_collection' do
    let(:collection){ FactoryBot.create(:collection) }
    before(:each) do
      @updater    = FactoryBot.create(:user)
      @admin_user = FactoryBot.create(:user)
      @collection = FactoryBot.create(:collection)
      @old_name = "Previous name"

      @email = NotificationsMailer.update_collection(
              updater_id: @updater.id,
              collection_id: @collection.id,
              user_id: @admin_user.id,
              old_name: @old_name,
              subject: "Notification: collection #{@old_name} changed to #{@collection.name}"
      )
    end

    it 'has correct e-mail address' do
      expect(@email).to deliver_to(@admin_user.email)
    end

    context 'subject' do
      it 'has collection name' do
        expect(@email).to have_subject(/#{@collection.name}/)
      end
    end

    context 'body' do
      it 'has link to collection' do
        expect(@email).to have_body_text(admin_collection_url(@collection))
      end

      it 'has collection name' do
        expect(@email).to have_body_text(@collection.name)
      end

      it 'has old collection name' do
        expect(@email).to have_body_text(@old_name)
      end

      it 'has updater e-mail' do
        expect(@email).to have_body_text(@updater.email)
      end

      it 'has collection description' do
        expect(@email).to have_body_text(@collection.description)
      end

      it 'has unit name' do
        expect(@email).to have_body_text(@collection.unit)
      end

      it 'has dropbox absolute path' do
        skip
      end
    end
   end
   describe '#new_collection' do
    let(:collection){ FactoryBot.create(:collection) }
    before(:each) do
      @creator    = FactoryBot.create(:user)
      @admin_user = FactoryBot.create(:user)
      @collection = FactoryBot.create(:collection)

      @email = NotificationsMailer.new_collection(
        creator_id: @creator.id,
        collection_id: @collection.id,
        user_id: @admin_user.id,
        subject: "New collection: #{@collection.name}",
      )
    end

    it 'has correct e-mail address' do
      expect(@email).to deliver_to(@admin_user.email)
    end

    context 'subject' do
      it 'has collection name' do
        expect(@email).to have_subject(/#{@collection.name}/)
      end
    end

    context 'body' do
      it 'has collection name' do
        expect(@email).to have_body_text(@collection.name)
      end

      it 'has creator e-mail' do
        expect(@email).to have_body_text(@creator.email)
      end

      it 'has collection description' do
        expect(@email).to have_body_text(@collection.description)
      end

      it 'has unit name' do
        expect(@email).to have_body_text(@collection.unit)
      end

      it 'has dropbox absolute path' do
        skip
      end
    end
  end
end
