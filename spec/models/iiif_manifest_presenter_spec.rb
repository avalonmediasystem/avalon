# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

describe IiifManifestPresenter do
  let(:media_object) { FactoryBot.build(:media_object) }
  let(:master_file) { FactoryBot.build(:master_file, media_object: media_object) }
  let(:presenter) { described_class.new(media_object: media_object, master_files: [master_file]) }

  context 'homepage' do
    subject { presenter.homepage.first }

    it 'provices a homepage' do
      expect(subject[:id]).to eq Rails.application.routes.url_helpers.media_object_url(media_object)
      expect(subject[:type]).to eq "Text"
      expect(subject[:format]).to eq "text/html"
      expect(subject[:label]).to include("none" => ["View in Repository"])
    end
  end

  context 'metadata' do
    let(:media_object) { FactoryBot.build(:fully_searchable_media_object) }
    subject do
      metadata_hash = {}
      presenter.manifest_metadata.map { |e| metadata_hash[e['label']] = e['value'] }
      metadata_hash
    end

    it 'provides metadata' do
      ['Title', 'Date', 'Main contributor', 'Summary', 'Contributor', 'Publisher', 'Genre', 'Subject', 'Time period',
       'Location', 'Collection', 'Unit', 'Language', 'Rights Statement', 'Terms of Use', 'Physical Description',
       'Related Item', 'Notes', 'Contents', 'Local Note', 'Other Identifiers'].each do |field|
        expect(subject).to include(field)
      end
    end
  end
end
