require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Checkout, type: :model do
  let(:checkout) { FactoryBot.create(:checkout) }

  describe 'validations' do
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
    let(:media_object) { FactoryBot.create(:media_object) }
    let!(:checkout) { FactoryBot.create(:checkout, media_object_id: media_object.id) }
    let!(:expired_checkout) { FactoryBot.create(:checkout, media_object_id: media_object.id, checkout_time: DateTime.now - 2.weeks, return_time: DateTime.now - 1.day) }

    describe 'active_for' do
      it 'returns active checkouts for the given media object' do
        expect(Checkout.active_for(media_object.id)).to include(checkout)
      end

      it 'does not return inactive checkouts' do
        expect(Checkout.active_for(media_object.id)).not_to include(expired_checkout)
      end
    end
  end

  describe 'media_object' do
    let(:media_object) { FactoryBot.create(:media_object) }
    let(:checkout) { FactoryBot.create(:checkout, media_object_id: media_object.id) }

    it 'returns the checked out MediaObject' do
      expect(checkout.media_object).to eq media_object
    end
  end
end
