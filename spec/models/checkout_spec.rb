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
require 'cancan/matchers'

RSpec.describe Checkout, type: :model do
  let(:checkout) { FactoryBot.create(:checkout) }

  describe 'validations' do
    let(:checkout) { FactoryBot.build(:checkout) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:media_object_id) }
    it { is_expected.to validate_presence_of(:checkout_time) }
    it { is_expected.to validate_presence_of(:return_time) }
  end

  describe 'abilities' do
    let(:user) { checkout.user }
    subject(:ability) { Ability.new(user, {}) }

    it { is_expected.to be_able_to(:create, checkout) }
    it { is_expected.to be_able_to(:read, checkout) }
    it { is_expected.to be_able_to(:update, checkout) }
    it { is_expected.to be_able_to(:destroy, checkout) }

    context 'when unable to read media object' do
      let(:private_media_object) { FactoryBot.create(:media_object) }
      let(:checkout) { FactoryBot.create(:checkout, media_object_id: private_media_object.id) }

      it { is_expected.not_to be_able_to(:create, checkout) }
    end

    context 'when checkout is owned by a different user' do
      let(:user) { FactoryBot.create(:user) }

      it { is_expected.not_to be_able_to(:create, checkout) }
      it { is_expected.not_to be_able_to(:read, checkout) }
      it { is_expected.not_to be_able_to(:update, checkout) }
      it { is_expected.not_to be_able_to(:destroy, checkout) }
    end
  end

  describe 'scopes' do
    let(:user) { FactoryBot.create(:user) }
    let(:media_object) { FactoryBot.create(:media_object) }
    let!(:checkout) { FactoryBot.create(:checkout, user: user, media_object_id: media_object.id) }
    let!(:user_checkout) { FactoryBot.create(:checkout, user: user) }
    let!(:other_checkout) { FactoryBot.create(:checkout) }
    let!(:expired_checkout) { FactoryBot.create(:checkout, user: user, media_object_id: media_object.id) }

    before do
      expired_checkout.update(return_time: DateTime.current - 1.day)
    end

    describe 'active_for_media_object' do
      it 'returns active checkouts for the given media object' do
        expect(Checkout.active_for_media_object(media_object.id)).to include(checkout)
      end

      it 'does not return inactive checkouts' do
        expect(Checkout.active_for_media_object(media_object.id)).not_to include(expired_checkout)
      end

      it 'does not return other checkouts' do
        expect(Checkout.active_for_media_object(media_object.id)).not_to include(other_checkout)
      end
    end

    describe 'active_for_user' do
      it 'returns active checkouts for the given user' do
        expect(Checkout.active_for_user(user.id)).to include(checkout)
      end

      it 'does not return inactive checkouts' do
        expect(Checkout.active_for_user(user.id)).not_to include(expired_checkout)
      end

      it 'does not return other checkouts' do
        expect(Checkout.active_for_media_object(media_object.id)).not_to include(other_checkout)
      end
    end

    describe 'returned_for_user' do
      it 'does not return active checkouts for the given user' do
        expect(Checkout.returned_for_user(user.id)).not_to include(checkout)
      end

      it 'does return inactive checkouts' do
        expect(Checkout.returned_for_user(user.id)).to include(expired_checkout)
      end

      it 'does not return other checkouts' do
        expect(Checkout.active_for_media_object(media_object.id)).not_to include(other_checkout)
      end
    end

    describe 'checked_out_to_user' do
      it 'returns the specified checkout' do
        expect(Checkout.checked_out_to_user(media_object.id, user.id)).to include(checkout)
      end

      it "does not return the user's other checkouts" do
        expect(Checkout.checked_out_to_user(media_object.id, user.id)).not_to include(user_checkout)
      end
    end
  end

  describe 'media_object' do
    let(:media_object) { FactoryBot.create(:media_object) }
    let(:checkout) { FactoryBot.create(:checkout, media_object_id: media_object.id) }

    it 'returns the checked out MediaObject' do
      expect(checkout.media_object.id).to eq media_object.id
    end
  end
end
