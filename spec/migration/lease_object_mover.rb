require 'rails_helper'

describe FedoraMigrate::Lease::ObjectMover do
  let(:lease) { FactoryGirl.create(:lease, inherited_read_users: [ FactoryGirl.create(:user).username ]) }
  describe 'empty?' do
    it 'returns true when the admin lease has been wiped' do
      described_class.wipeout!(lease)
      expect(described_class.empty?(lease)).to be_truthy
    end
    it 'returns false if the admin lease has any information' do
      expect(described_class.empty?(lease)).to be_falsey
    end
  end
  describe 'wipeout!' do
    it 'wipes all of the data' do
      resources = [:resource, :default_permissions]
      resources.each do |res|
        expect(lease.send(res).blank?).to be_falsey
      end
      expect(described_class.empty?(lease)).to be_falsey
      described_class.wipeout!(lease)
      resources.each do |res|
        expect(lease.send(res).blank?).to be_truthy
      end
      expect(described_class.empty?(lease)).to be_truthy
    end
  end
end
