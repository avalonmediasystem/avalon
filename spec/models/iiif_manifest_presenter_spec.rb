# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

  context 'to_s' do
    it "returns the media object's title" do
      expect(presenter.to_s).to eq media_object.title
    end

    context 'when media object is missing title' do
      it "returns the media object's id" do
        allow(media_object).to receive(:title).and_return(nil)
        expect(presenter.to_s).to eq media_object.id
      end
    end
  end

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

      [
        'Title', 'Alternative title', 'Publication date', 'Creation date', 'Main contributor', 'Summary', 'Contributor', 'Publisher', 'Genre', 'Subject',
        'Time period', 'Geographic Subject', 'Collection', 'Unit', 'Language', 'Rights Statement', 'Terms of Use', 'Physical Description', 'Series',
        'Related Item', 'Notes', 'Table of Contents', 'Local Note', 'Other Identifier', 'Access Restrictions', 'Bibliographic ID'
      ].each do |field|
        expect(subject).to include(field)
      end
      expect(subject).to_not include('Lending Period')
    end

    context 'with duplicate identifiers' do
      let(:media_object) do
        FactoryBot.build(:fully_searchable_media_object).tap do |mo|
          mo.other_identifier += mo.other_identifier
          mo.other_identifier += [mo.bibliographic_id]
        end
      end

      it 'de-dupes other identifiers' do
        allow_any_instance_of(IiifManifestPresenter).to receive(:lending_enabled).and_return(false)
        expect(subject['Bibliographic ID'].first).to include media_object.bibliographic_id[:id]
        expect(subject['Other Identifier'].size).to eq 1
        other_id = subject['Other Identifier'].first.match(/.+: (.+)/)[1]
        expect(other_id).not_to eq media_object.bibliographic_id[:id]
        expect(other_id).to eq media_object.other_identifier.first[:id]
      end
    end

    context 'when controlled digital lending is enabled' do
      it 'provides metadata' do
        allow_any_instance_of(IiifManifestPresenter).to receive(:lending_enabled).and_return(true)

        [
          'Title', 'Publication date', 'Creation date', 'Main contributor', 'Summary', 'Contributor', 'Publisher', 'Genre', 'Subject',
          'Time period', 'Geographic Subject', 'Collection', 'Unit', 'Language', 'Rights Statement', 'Terms of Use', 'Physical Description', 'Series',
          'Related Item', 'Notes', 'Table of Contents', 'Local Note', 'Other Identifier', 'Access Restrictions', 'Bibliographic ID', 'Lending Period'
        ].each do |field|
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

    context 'values with search links' do
      it 'includes appropriate link tags' do
        search_url = Rails.application.routes.url_helpers.blacklight_url.gsub('/', '\/')
        ['Subject'].each do |field|
          subject[field].each do |value|
            expect(value).to match(/^<a href="#{search_url}\?f%5B.+%5D%5B%5D=.*">.*<\/a>$/)
          end
        end
      end
    end

    context 'date handling' do
      let(:media_object) { FactoryBot.build(:media_object, date_issued: '2025-07-22', date_created: '2025-07-01') }

      it 'returns human readable date' do
        expect(subject['Publication date'].first).to eq 'July 22, 2025'
        expect(subject['Creation date'].first).to eq 'July 1, 2025'
      end

      context 'unknown/unknown' do
        let(:media_object) { FactoryBot.build(:media_object, date_issued: 'unknown/unknown', date_created: 'unknown/unknown') }

        it 'returns "unknown"' do
          expect(subject['Publication date'].first).to eq 'unknown'
          expect(subject['Creation date'].first).to eq 'unknown'
        end
      end

      context 'invalid date' do
        let(:media_object) { FactoryBot.build(:media_object, date_issued: 'not_a date', date_created: false) }

        it 'returns nil' do
          expect(subject['Publication date']).to be_nil
          expect(subject['Creation date']).to be_nil
        end
      end
    end
  end

  context 'viewing_hint' do
    subject { presenter.viewing_hint }

    it 'includes auto-advance' do
      expect(subject).to include 'auto-advance'
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
