require 'rails_helper'

describe IiifManifestPresenter do
  let(:media_object) { FactoryBot.build(:media_object) }
  let(:master_file) { FactoryBot.build(:master_file, media_object: media_object) }
  let(:presenter) { described_class.new(media_object: media_object, master_files: [master_file]) }

  context 'homepage' do
    subject { presenter.homepage }

    it 'provices a homepage' do
      expect(subject[:id]).to eq Rails.application.routes.url_helpers.media_object_url(media_object)
      expect(subject[:type]).to eq "Text"
      expect(subject[:format]).to eq "text/html"
      expect(subject[:label]).to include("@none" => ["View in Repository"])
    end
  end
end
