require 'rails_helper'

describe FedoraMigrate::Derivative::ObjectMover do
  let(:derivative) { FactoryGirl.create(:derivative) }
  describe 'empty?' do
    it 'returns true when the derivative has been wiped' do
      described_class.wipeout!(derivative)
      expect(described_class.empty?(derivative)).to be_truthy
    end
    it 'returns false if the derivative has any information' do
      expect(described_class.empty?(derivative)).to be_falsey
    end
  end
  describe 'wipeout!' do
    it 'wipes all of the data' do
      resources = [:resource]
      resources.each do |res|
        expect(derivative.send(res).blank?).to be_falsey
      end
      expect(described_class.empty?(derivative)).to be_falsey
      described_class.wipeout!(derivative)
      resources.each do |res|
        expect(derivative.send(res).blank?).to be_truthy
      end
      expect(described_class.empty?(derivative)).to be_truthy
    end
  end
end
