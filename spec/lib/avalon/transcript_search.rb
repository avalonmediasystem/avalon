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

  let(:transcript) { FactoryBot.create(:supplemental_file, :with_transcript_tag, parent_id: parent_master_file.id, file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'chunk_test.vtt'), transcript_mime_type)) }
  let(:transcript_global_id) { transcript.to_global_id.to_s }
  let(:transcript_mime_type) { 'text/vtt' }
  let(:transcript2) { FactoryBot.create(:supplemental_file, :with_transcript_tag, parent_id: parent_master_file.id, file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'chunk_test.txt'), transcript2_mime_type)) }
  let(:transcript2_global_id) { transcript2.to_global_id.to_s }
  let(:transcript2_mime_type) { 'text/plain' }
  let(:parent_master_file) { FactoryBot.create(:master_file, :with_media_object) }

  before :each do
    parent_master_file.supplemental_files += [transcript, transcript2]
    parent_master_file.save
  end

  describe '#perform_search' do
    it 'returns a solr document of transcript chunks with the matching term' do
      search = subject.perform_search
      expect(search['response']['docs'].count).to eq 2
      expect(search['response']['docs']).to include({"id"=>transcript_global_id, "mime_type_ssi"=>transcript_mime_type})
      expect(search['response']['docs']).to include({"id"=>transcript2_global_id, "mime_type_ssi"=>transcript2_mime_type})
      expect(search['highlighting'][transcript_global_id]['transcript_tsim']).to be_a Array
      expect(search['highlighting'][transcript_global_id]['transcript_tsim'].count).to eq 1
      expect(search['highlighting'][transcript_global_id]['transcript_tsim'].first).to include '<em>before</em>'
      expect(search['highlighting'][transcript2_global_id]['transcript_tsim']).to be_a Array
      expect(search['highlighting'][transcript2_global_id]['transcript_tsim'].count).to eq 1
      expect(search['highlighting'][transcript2_global_id]['transcript_tsim'].first).to include '<em>before</em>'
    end

    context 'with multiple terms in the query' do
      subject { described_class.new(query: 'before lunch', master_file: parent_master_file) }

      it 'returns a solr document of transcript chunks' do
        search = subject.perform_search
        # solr search is case insensitive, so we convert results to lower case for simpler testing
        expect(search['highlighting'][transcript_global_id]['transcript_tsim'].all? { |h| h.downcase.include?('<em>before</em> <em>lunch</em>') }).to eq true
        expect(search['highlighting'][transcript_global_id]['transcript_tsim'].count).to eq 1
      end

      context 'with phrase searching disabled' do
        it 'returns a solr document of transcript chunks with any of the matching terms' do
          search = subject.perform_search(phrase_searching: false)
          # solr search is case insensitive, so we convert results to lower case for simpler testing
          expect(search['highlighting'][transcript_global_id]['transcript_tsim'].all? { |h| h.downcase.include?('<em>before</em>') || h.downcase.include?('<em>lunch</em>') }).to eq true
          expect(search['highlighting'][transcript_global_id]['transcript_tsim'].count).to eq 4
        end
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
      expect(items.first[:id]).to eq "#{Rails.application.routes.url_helpers.media_object_url(parent_master_file.media_object_id)}/manifest/canvas/#{parent_master_file.id}/search/abc1234"
      expect(items.first[:type]).to eq 'Annotation'
      expect(items.first[:motivation]).to eq 'supplementing'
      expect(items.first[:body]).to be_present
      expect(items.first[:body][:type]).to eq 'TextualBody'
      expect(items.first[:body][:value]).to be_a String
      expect(items.first[:body][:value]).to include '<em>before</em>'
      expect(items.first[:body][:format]).to eq 'text/plain'
      expect(items.first[:target]).to eq Rails.application.routes.url_helpers.transcripts_master_file_supplemental_file_url(parent_master_file.id, transcript.id, anchor: "t=00:00:22.200,00:00:26.600")
      expect(items.second[:id]).to eq "#{Rails.application.routes.url_helpers.media_object_url(parent_master_file.media_object_id)}/manifest/canvas/#{parent_master_file.id}/search/abc1234"
      expect(items.second[:type]).to eq 'Annotation'
      expect(items.second[:motivation]).to eq 'supplementing'
      expect(items.second[:body]).to be_present
      expect(items.second[:body][:type]).to eq 'TextualBody'
      expect(items.second[:body][:value]).to be_a String
      expect(items.second[:body][:value]).to include '<em>before</em>'
      expect(items.second[:body][:format]).to eq 'text/plain'
      expect(items.second[:target]).to eq Rails.application.routes.url_helpers.transcripts_master_file_supplemental_file_url(parent_master_file.id, transcript2.id)

    end

    context 'transcript with timed text' do
      it 'returns result value without time cues' do
        item = subject.iiif_content_search[:items].first
        expect(item[:body][:value]).to_not match(/\d{2}:\d{2}:\d{2}/)
      end

      it 'returns result target with time cue' do
        item = subject.iiif_content_search[:items].first
        expect(item[:target]).to include '#t=00:00:22.200,00:00:26.600'
      end
    end
  end
end
