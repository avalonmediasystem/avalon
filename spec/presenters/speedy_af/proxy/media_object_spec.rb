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

describe SpeedyAF::Proxy::MediaObject do
  let(:media_object) { FactoryBot.create(:media_object) }
  subject(:presenter) { described_class.find(media_object.id) }

  describe "#visibility" do
    context 'when private' do
      it 'returns private' do
        expect(presenter.visibility).to eq 'private'
      end
    end
    context 'when protected' do
      let(:media_object) { FactoryBot.create(:media_object, visibility: 'restricted') }
      it 'returns restricted' do
        expect(presenter.visibility).to eq 'restricted'
      end
    end
    context 'when public' do
      let(:media_object) { FactoryBot.create(:media_object, visibility: 'public') }
      it 'returns public' do
        expect(presenter.visibility).to eq 'public'
      end
    end
  end

  context "fully searchable media object proxy" do
    let(:media_object) { FactoryBot.create(:fully_searchable_media_object, :with_master_file) }
    it "should include all metadata fields" do
      expect(presenter.title).to eq media_object.title
      expect(presenter.date_created).to eq media_object.date_created
      expect(presenter.date_issued).to eq media_object.date_issued
      expect(presenter.copyright_date).to eq media_object.copyright_date
      expect(presenter.creator).to eq media_object.creator
      expect(presenter.abstract).to eq media_object.abstract
      expect(presenter.contributor).to eq media_object.contributor
      expect(presenter.publisher).to eq media_object.publisher
      expect(presenter.genre).to eq media_object.genre
      expect(presenter.topical_subject).to eq media_object.topical_subject
      expect(presenter.temporal_subject).to eq media_object.temporal_subject
      expect(presenter.geographic_subject).to eq media_object.geographic_subject
      expect(presenter.collection.id).to eq media_object.collection.id
      expect(presenter.collection.unit.name).to eq media_object.collection.unit.name
      expect(presenter.language).to eq media_object.language
      expect(presenter.rights_statement).to eq media_object.rights_statement
      expect(presenter.terms_of_use).to eq media_object.terms_of_use
      expect(presenter.physical_description).to eq media_object.physical_description
      expect(presenter.related_item_url).to eq media_object.related_item_url
      expect(presenter.table_of_contents).to eq media_object.table_of_contents
      expect(presenter.note).to eq media_object.note
      expect(presenter.other_identifier).to eq media_object.other_identifier
      expect(presenter.comment).to eq media_object.comment.to_a
      expect(presenter.visibility).to eq media_object.visibility
      expect(presenter.section_list).to eq media_object.section_list
      expect(presenter.section_ids).to eq media_object.section_ids
    end
  end

  describe 'attributes' do
    let(:media_object) { FactoryBot.create(:fully_searchable_media_object, :with_master_file, permalink: 'http://permalink', supplemental_files_json: '[]', duration: 10, avalon_uploader: 'user1', identifier: ['abc123'], lending_period: 12000) }

    it 'returns all attributes' do
      expect(presenter.permalink).to be_present
      expect(presenter.supplemental_files_json).to be_present
      expect(presenter.duration).to be_present
      expect(presenter.avalon_resource_type).to be_present
      expect(presenter.avalon_publisher).to be_present
      expect(presenter.avalon_uploader).to be_present
      expect(presenter.identifier).to be_present
      expect(presenter.comment).to be_present
      expect(presenter.lending_period).to be_present
    end
  end

  describe '#sections' do
    let(:section1) { FactoryBot.create(:master_file, media_object: media_object) }
    let(:section2) { FactoryBot.create(:master_file, media_object: media_object) }
    let(:media_object) { FactoryBot.create(:media_object) }

    context 'when no sections present' do
      it 'returns empty array without reifying' do
        expect(presenter.sections).to eq []
        expect(presenter.real?).to eq false
      end
    end

    it 'returns array of master file proxy objects in proper order' do
      section1
      section2
      expect(presenter.sections.map(&:id)).to eq media_object.section_ids
      expect(presenter.sections.map(&:class)).to eq [SpeedyAF::Proxy::MasterFile, SpeedyAF::Proxy::MasterFile]
    end
  end
end
