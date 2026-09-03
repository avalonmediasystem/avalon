require 'rails_helper'

RSpec.describe Admin::ApplicationSetting, type: :model do
  describe 'validations' do
    it 'enforces singleton_guard == 0' do
      expect(described_class.new(singleton_guard: 1).save).to be_falsey
      expect(described_class.new(singleton_guard: 0).save).to be_truthy
    end
  end

  describe '.instance' do
    it 'creates new entry if database is empty' do
      expect { described_class.instance }.to change { described_class.count }.from(0).to(1)
    end

    it 'finds existing db entry if db is populated' do
      setting = described_class.create
      expect { described_class.instance }.to_not change { described_class.count }
      expect(described_class.instance).to eq setting
    end
  end

  describe 'missing method handling' do
    subject { described_class.instance }

    context '#respond_to_missing?' do
      it 'returns true for Config gem settings' do
        expect(subject.respond_to?(:domain)).to be_truthy
      end

      it 'returns false for non-existing settings' do
        expect(subject.respond_to?(:mint)).to be_falsey
      end
    end

    context '#method_missing' do
      it 'falls back to Config gem' do
        expect(Settings).to receive(:domain)
        subject.domain
      end

      it 'raises an error if the setting does not exist' do
        expect { subject.mint }.to raise_error
      end
    end
  end
end
