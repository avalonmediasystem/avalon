require 'rails_helper'

RSpec.describe Admin::ApplicationSetting, type: :model do
  describe 'validations' do
    it 'enforces singleton_guard' do
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
end
