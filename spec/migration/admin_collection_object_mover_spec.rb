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
      resources = [:resource, :default_permissions, :access_control]
      resources.each do |res|
        expect(collection.send(res).blank?).to be_falsey
      end
      expect(described_class.empty?(collection)).to be_falsey
      described_class.wipeout!(collection)
      resources.each do |res|
        expect(collection.send(res).blank?).to be_truthy
      end
      expect(described_class.empty?(collection)).to be_truthy
    end
  end
end
