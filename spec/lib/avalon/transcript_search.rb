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
require 'avalon/transcript_search'

describe Avalon::TranscriptSearch do
  subject { described_class.new(query: 'before', master_file: parent_master_file) }

  let(:transcript) { FactoryBot.create(:supplemental_file, :with_transcript_tag, parent_id: parent_master_file.id, file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'chunk_test.txt'), 'text/plain')) }
  let(:parent_master_file) { FactoryBot.create(:master_file, :with_media_object) }

  before :each do
    parent_master_file.supplemental_files += [transcript]
    parent_master_file.save
  end

  describe '#perform_search' do
    it 'returns a solr document of transcript chunks with the matching term' do
      search = subject.perform_search
      global_id = transcript.to_global_id.to_s
      expect(search['response']['docs'].first['id']).to eq global_id
      expect(search['response']['docs'].first['mime_type_ssi']).to eq transcript.file.content_type
      expect(search['highlighting'][global_id]['transcript_tsim']).to be_a Array
      expect(search['highlighting'][global_id]['transcript_tsim'].count).to eq 1
      expect(search['highlighting'][global_id]['transcript_tsim'].first).to include '<em>before</em>'
    end

    context 'with multiple terms in the query' do
      subject { described_class.new(query: 'before lunch', master_file: parent_master_file) }
      let(:transcript) { FactoryBot.create(:supplemental_file, :with_transcript_tag, parent_id: parent_master_file.id, file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'chunk_test.vtt'), 'text/vtt')) }
      
      it 'returns a solr document of transcript chunks with any of the matching terms' do
        search = subject.perform_search
        global_id = transcript.to_global_id.to_s
        # solr search is case insensitive, so we convert results to lower case for simpler testing
        expect(search['highlighting'][global_id]['transcript_tsim'].all? { |h| h.downcase.include?('<em>before</em>') || h.downcase.include?('<em>lunch</em>') }).to eq true
      end
    end
  end

  describe '#iiif_content_search' do
    it 'returns results in compliance with IIIF Content Search 2.0' do
      allow(SecureRandom).to receive(:uuid).and_return('abc1234')
      search = subject.iiif_content_search
      expect(search["@context".to_sym]).to eq "http://iiif.io/api/search/2/context.json"
      expect(search[:id]).to eq "#{Rails.application.routes.url_helpers.search_master_file_url(parent_master_file.id)}?q=before"
      expect(search[:type]).to eq "AnnotationPage"
      expect(search[:items]).to be_present
      items = search[:items]
      expect(items).to be_a Array
      item = items.first
      expect(item[:id]).to eq "#{Rails.application.routes.url_helpers.media_object_url(parent_master_file.media_object_id)}/manifest/canvas/#{parent_master_file.id}/search/abc1234"
      expect(item[:type]).to eq 'Annotation'
      expect(item[:motivation]).to eq 'supplementing'
      expect(item[:body]).to be_present
      expect(item[:body][:type]).to eq 'TextualBody'
      expect(item[:body][:value]).to be_a String
      expect(item[:body][:value]).to include '<em>before</em>'
      expect(item[:body][:format]).to eq 'text/plain'
      expect(item[:target]).to eq Rails.application.routes.url_helpers.transcripts_master_file_supplemental_file_url(parent_master_file.id, transcript.id)
    end
  end
end