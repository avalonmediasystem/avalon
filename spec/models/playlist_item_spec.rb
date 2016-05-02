require 'spec_helper'

RSpec.describe PlaylistItem, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:playlist) }
    it { is_expected.to validate_presence_of(:annotation) }
  end
end
