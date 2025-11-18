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

RSpec.describe SearchBuilder do
  subject(:builder) { described_class.new(processor_chain, scope) }

  let(:processor_chain) { [] }
  let(:scope) { CatalogController.new }
  let(:manager) { FactoryBot.create(:manager) }
  let(:ability) { Ability.new(manager) }

  describe "#only_published_items" do
    it "should include policy clauses when user is manager" do
      allow(subject).to receive(:current_ability).and_return(ability)
      allow(subject).to receive(:policy_clauses).and_return("test:clause")
      expect(subject.only_published_items({})).to eq "test:clause OR workflow_published_sim:\"Published\""
    end
  end

  describe "#search_section_transcripts" do
    let(:solr_parameters) { { q: 'Example' } }
    context "without transcripts present" do
      it "should return nil" do
        expect(subject.search_section_transcripts(solr_parameters)).to eq nil
      end
    end

    context "with transcripts present" do
      # Creating the transcript as a `let() {}` block was not adding it to the database in a way that
      # the conditional in the model could see. Running the create in a :before block works.
      before { FactoryBot.create(:supplemental_file, :with_transcript_file, :with_transcript_tag) }

      it "should add section transcript searching to the solr query" do
        subject.search_section_transcripts(solr_parameters)
        expect(solr_parameters[:q]).to eq "has_model_ssim:MediaObject AND (Example _query_:\"{!join to=id from=isPartOf_ssim}{!join to=id from=isPartOf_ssim}transcript_tsim:(Example)\")"
      end

      context "phrase searching" do
        let(:solr_parameters) { { q: '"Example captions"' } }

        it "should only match transcripts with the phrase" do
          subject.search_section_transcripts(solr_parameters)
          expect(solr_parameters[:q]).to eq "has_model_ssim:MediaObject AND (\\\"Example captions\\\" _query_:\"{!join to=id from=isPartOf_ssim}{!join to=id from=isPartOf_ssim}transcript_tsim:(\\\"Example captions\\\")\")"
        end
      end
    end
  end

  describe "#term_frequency_counts" do
    let(:solr_parameters) { { q: 'Example' } }
    context "without transcripts present" do
      it "should skip transcript options in query" do
        subject.term_frequency_counts(solr_parameters)
        expect(solr_parameters[:fl]).to include "metadata_tf_0:termfreq(mods_tesim,Example),structure_tf_0:termfreq(section_label_tesim,Example)"
        expect(solr_parameters[:fl]).to_not include "transcripts_tf_0"
      end
    end

    context "with transcripts present" do
      before { FactoryBot.create(:supplemental_file, :with_transcript_file, :with_transcript_tag) }

      it "should add transcript options to query" do
        subject.term_frequency_counts(solr_parameters)
        expect(solr_parameters[:fl]).to include "metadata_tf_0:termfreq(mods_tesim,Example),structure_tf_0:termfreq(section_label_tesim,Example),transcript_tf_0"
        expect(solr_parameters["sections.fl"]).to eq "id,transcript_tf_0,transcripts:[subquery]"
        expect(solr_parameters["sections.transcripts.fl"]).to eq "id,transcript_tf_0:termfreq(transcript_tsim,Example)"
        expect(solr_parameters["sections.transcripts.q"]).to eq "{!terms f=isPartOf_ssim v=$row.id}{!join to=id from=isPartOf_ssim}"
      end

      context 'with multiple terms' do
        let(:solr_parameters) { { q: 'Example query' } }

        it "should add transcript options to query" do
          subject.term_frequency_counts(solr_parameters)
          expect(solr_parameters[:fl]).to include "metadata_tf_0:termfreq(mods_tesim,Example),structure_tf_0:termfreq(section_label_tesim,Example),transcript_tf_0"
          expect(solr_parameters[:fl]).to include "metadata_tf_1:termfreq(mods_tesim,query),structure_tf_1:termfreq(section_label_tesim,query),transcript_tf_1"
          expect(solr_parameters["sections.fl"]).to eq "id,transcript_tf_0,transcript_tf_1,transcripts:[subquery]"
          expect(solr_parameters["sections.transcripts.fl"]).to include "transcript_tf_0:termfreq(transcript_tsim,Example)"
          expect(solr_parameters["sections.transcripts.fl"]).to include "transcript_tf_1:termfreq(transcript_tsim,query)"
          expect(solr_parameters["sections.transcripts.q"]).to eq "{!terms f=isPartOf_ssim v=$row.id}{!join to=id from=isPartOf_ssim}"
        end

        context 'with CJK whitespace' do
          let(:solr_parameters) { { q: 'Example　query' } }

          it "should add transcript options to query" do
            subject.term_frequency_counts(solr_parameters)
            expect(solr_parameters[:fl]).to include "metadata_tf_0:termfreq(mods_tesim,Example),structure_tf_0:termfreq(section_label_tesim,Example),transcript_tf_0"
            expect(solr_parameters[:fl]).to include "metadata_tf_1:termfreq(mods_tesim,query),structure_tf_1:termfreq(section_label_tesim,query),transcript_tf_1"
            expect(solr_parameters["sections.fl"]).to eq "id,transcript_tf_0,transcript_tf_1,transcripts:[subquery]"
            expect(solr_parameters["sections.transcripts.fl"]).to include "transcript_tf_0:termfreq(transcript_tsim,Example)"
            expect(solr_parameters["sections.transcripts.fl"]).to include "transcript_tf_1:termfreq(transcript_tsim,query)"
            expect(solr_parameters["sections.transcripts.q"]).to eq "{!terms f=isPartOf_ssim v=$row.id}{!join to=id from=isPartOf_ssim}"
          end
        end
      end
    end
  end
end
