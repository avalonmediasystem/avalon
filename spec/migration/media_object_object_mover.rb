require 'rails_helper'

describe FedoraMigrate::MediaObject::ObjectMover do
  let(:media_object) { FactoryGirl.create(:media_object, :with_master_file, :with_completed_workflow) }
  describe 'empty?' do
    it 'returns true when the media object has been wiped' do
      described_class.wipeout!(media_object)
      expect(described_class.empty?(media_object)).to be_truthy
    end
    it 'returns false if the media object has any information' do
      expect(described_class.empty?(media_object)).to be_falsey
    end
  end
  describe 'wipeout!' do
    it 'wipes all of the data' do
      resources = [:resource, :access_control, :descMetadata, :workflow, :master_files]
      resources.each do |res|
        expect(media_object.send(res).blank?).to be_falsey
      end
      expect(media_object.ordered_master_files.to_a.blank?).to be_falsey
      expect(described_class.empty?(media_object)).to be_falsey
      described_class.wipeout!(media_object)
      resources.each do |res|
        expect(media_object.send(res).blank?).to be_truthy
      end
      expect(media_object.ordered_master_files.to_a.blank?).to be_truthy
      expect(described_class.empty?(media_object)).to be_truthy
    end
  end
end
