require 'rails_helper'

describe FedoraMigrate::AdminCollection::ObjectMover do
  let(:collection) { FactoryGirl.create(:collection) }
  describe 'empty?' do
    it 'returns true when the admin collection has been wiped' do
      described_class.wipeout!(collection)
      expect(described_class.empty?(collection)).to be_truthy
    end
    it 'returns false if the admin collection has any information' do
      expect(described_class.empty?(collection)).to be_falsey
    end
  end
  describe 'wipeout!' do
    it 'wipes all of the data' do
      expect(collection.resource.blank?).to be_falsey
      expect(collection.default_permissions.blank?).to be_falsey
      expect(collection.access_control.blank?).to be_falsey
      expect(described_class.empty?(collection)).to be_falsey
      described_class.wipeout!(collection)
      expect(collection.resource.blank?).to be_truthy
      expect(collection.default_permissions.blank?).to be_truthy
      expect(collection.access_control.blank?).to be_truthy
      expect(described_class.empty?(collection)).to be_truthy
    end
  end
end
