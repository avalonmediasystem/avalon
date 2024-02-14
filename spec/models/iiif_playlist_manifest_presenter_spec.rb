# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'rails_helper'

describe IiifPlaylistManifestPresenter do
  let(:playlist) { FactoryBot.create(:playlist, tags: ['Test']) }
  let(:playlist_item) { FactoryBot.build(:playlist_item, playlist: playlist) }
  let(:presenter) { described_class.new(playlist: playlist, items: [playlist_item]) }

  context 'homepage' do
    subject { presenter.homepage.first }

    it 'provides a homepage' do
      expect(subject[:id]).to eq Rails.application.routes.url_helpers.playlist_url(playlist)
      expect(subject[:type]).to eq "Text"
      expect(subject[:format]).to eq "text/html"
      expect(subject[:label]).to include("none" => ["View in Repository"])
    end
  end

  context 'metadata' do
    subject do
      metadata_hash = {}
      presenter.manifest_metadata.map { |e| metadata_hash[e['label']] = e['value'] }
      metadata_hash
    end

    it 'provides metadata' do
      ['Title', 'Description', 'Tags'].each do |field|
        expect(subject).to include(field)
      end
    end
  end

  context 'viewing_hint' do
    subject { presenter.viewing_hint }

    it 'includes auto-advance' do
      expect(subject).to include 'auto-advance'
    end
  end
end
