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

    it 'provides a homepage' do
      expect(subject[:id]).to eq Rails.application.routes.url_helpers.media_object_url(media_object)
      expect(subject[:type]).to eq "Text"
      expect(subject[:format]).to eq "text/html"
      expect(subject[:label]).to include("none" => ["View in Repository"])
    end

    context 'with permalink' do
      let(:media_object) { FactoryBot.build(:media_object, permalink: "https://purl.example.edu/permalink") }

      it 'uses the permalink' do
        expect(subject[:id]).to eq media_object.permalink
      end
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
      allow_any_instance_of(IiifManifestPresenter).to receive(:lending_enabled).and_return(false)

      ['Title', 'Date', 'Main contributor', 'Summary', 'Contributor', 'Publisher', 'Genre', 'Subject', 'Time period',
       'Location', 'Collection', 'Unit', 'Language', 'Rights Statement', 'Terms of Use', 'Physical Description',
       'Related Item', 'Notes', 'Table of Contents', 'Local Note', 'Other Identifiers', 'Access Restrictions'].each do |field|
        expect(subject).to include(field)
      end
      expect(subject).to_not include('Lending Period')
    end

    context 'when controlled digital lending is enabled' do
      it 'provides metadata' do
        allow_any_instance_of(IiifManifestPresenter).to receive(:lending_enabled).and_return(true)

        ['Title', 'Date', 'Main contributor', 'Summary', 'Contributor', 'Publisher', 'Genre', 'Subject', 'Time period',
         'Location', 'Collection', 'Unit', 'Language', 'Rights Statement', 'Terms of Use', 'Physical Description',
         'Related Item', 'Notes', 'Table of Contents', 'Local Note', 'Other Identifiers', 'Access Restrictions', 'Lending Period'].each do |field|
          expect(subject).to include(field)
        end
      end
    end

    context 'multiple values' do
      let(:media_object) { FactoryBot.build(:fully_searchable_media_object, note: [{ note: Faker::Lorem.paragraph, type: 'general' }, { note: Faker::Lorem.paragraph, type: 'general' }]) }

      it 'serializes multiple values as an array' do
        expect(subject['Notes']).to be_a Array
      end
    end
  end

  describe '#sequence_rendering' do
    let(:media_object) { FactoryBot.build(:fully_searchable_media_object, supplemental_files_json: supplemental_files_json) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
    let(:supplemental_files) { [supplemental_file] }
    let(:supplemental_files_json) { supplemental_files.map(&:to_global_id).map(&:to_s).to_s }

    subject { presenter.sequence_rendering }

    it 'includes supplemental files' do
      expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{supplemental_file.id}/ }).to eq true
    end
  end
end
