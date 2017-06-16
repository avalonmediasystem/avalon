require 'rails_helper'

describe FedoraMigrate::MasterFile::ObjectMover do
  let(:master_file) { FactoryGirl.create(:master_file, :with_derivative, :with_thumbnail, :with_poster, :with_structure, :with_captions) }
  describe 'empty?' do
    it 'returns true when the master file has been wiped' do
      described_class.wipeout!(master_file)
      expect(described_class.empty?(master_file)).to be_truthy
    end
    it 'returns false if the master file has any information' do
      expect(described_class.empty?(master_file)).to be_falsey
    end
  end
  describe 'wipeout!' do
    it 'wipes all of the data' do
      resources = [:resource, :thumbnail, :structuralMetadata, :captions, :poster]
      resources.each do |res|
        expect(master_file.send(res).blank?).to be_falsey
      end
      expect(described_class.empty?(master_file)).to be_falsey
      described_class.wipeout!(master_file)
      resources.each do |res|
        expect(master_file.send(res).blank?).to be_truthy
      end
      expect(described_class.empty?(master_file)).to be_truthy
    end
  end
end
