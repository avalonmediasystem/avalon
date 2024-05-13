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

describe SupplementalFile do
  let(:subject) { FactoryBot.create(:supplemental_file) }

  describe 'validations' do
    describe 'file type' do
      context 'non-caption file' do
        let(:subject) { FactoryBot.create(:supplemental_file, :with_attached_file) }
        it 'should skip validation' do
          expect(subject.valid?).to be_truthy
        end
      end
      context 'VTT caption file' do
        let(:subject) { FactoryBot.create(:supplemental_file, :with_caption_file, :with_caption_tag) }
        it 'should validate' do
          expect(subject.valid?).to be_truthy
        end
      end
      context 'SRT caption file' do
        let(:subject) { FactoryBot.create(:supplemental_file, :with_caption_srt_file, :with_caption_tag) }
        it 'should validate' do
          expect(subject.valid?).to be_truthy
        end
      end
      context 'non-VTT/non-SRT caption file' do
        let(:subject) { FactoryBot.build(:supplemental_file, :with_attached_file, :with_caption_tag) }
        it 'should not validate' do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:file_type]).not_to be_empty
        end
      end
    end

    describe 'scopes' do
      describe 'with_tag' do
        let!(:subject) { FactoryBot.create(:supplemental_file, tags: ['transcript', 'machine_generated']) }
        let!(:other_transcript) { FactoryBot.create(:supplemental_file, tags: ['transcript']) }
        let!(:another_file) { FactoryBot.create(:supplemental_file, :with_caption_file, tags: ['caption']) }

        it 'filters for a single tag' do
          expect(SupplementalFile.with_tag('transcript')).to include(subject,other_transcript)
          expect(SupplementalFile.with_tag('transcript').count).to eq 2
        end

        it 'filters for multiple tags' do
          expect(SupplementalFile.with_tag('transcript').with_tag('machine_generated').first).to eq subject
          expect(SupplementalFile.with_tag('transcript').with_tag('machine_generated').count).to eq 1
        end
      end
    end

    describe '#to_solr' do
      # TODO: Update tests once chunking is in place
      let(:caption) { FactoryBot.create(:supplemental_file, :with_caption_file, :with_caption_tag) }
      let(:transcript) { FactoryBot.create(:supplemental_file, :with_transcript_file, :with_transcript_tag) }
      let(:caption_transcript) { FactoryBot.create(:supplemental_file, :with_caption_file, tags: ['caption', 'transcript']) }

      it "should solrize transcripts" do
        expect(transcript.to_solr[ "transcript_tsim" ]).to be_a Array
        expect(transcript.to_solr[ "transcript_tsim" ][0]).to eq "WEBVTT FILE\r \r 1\r 00:00:03.500 --> 00:00:05.000\r Example captions"
        expect(caption_transcript.to_solr[ "transcript_tsim" ]).to be_a Array
        expect(transcript.to_solr[ "transcript_tsim" ][0]).to eq "WEBVTT FILE\r \r 1\r 00:00:03.500 --> 00:00:05.000\r Example captions"
      end

      it "should not solrize non-transcripts" do
        expect(caption.to_solr[ "transcript_tsim" ]).to be nil
      end
    end

    describe 'language' do
      it 'should validate valid language' do
        subject.language = 'eng'
        expect(subject.valid?).to be_truthy
      end
      it 'should not validate invalid language' do
        subject.language = 'engl'
        expect(subject.valid?).to be_falsey
      end
    end
  end

  it "stores no tags by default" do
    expect(subject.tags).to match_array([])
  end

  context "with valid tags" do
    let(:subject) { FactoryBot.create(:supplemental_file, :with_caption_file)}
    let(:tags) { ["transcript", "caption", "machine_generated"] }

    it "can store tags" do
      subject.tags = tags
      subject.save
      expect(subject.reload.tags).to match_array(tags)
    end
  end

  context "with invalid tags" do
    let(:bad_tags) { ["unallowed"] }

    it "does not store tags" do
      subject.tags = bad_tags
      expect(subject.save).to be_falsey
      expect(subject.errors.messages[:tags]).to include("unallowed is not an allowed value")
    end
  end

  context 'language' do
    it "can be edited" do
      subject.language = 'ger'
      subject.save
      expect(subject.reload.language).to eq "ger"
    end
  end

  describe '.convert_from_srt' do
    let(:input) { "1\n00:00:03,498 --> 00:00:05,000\n- Example Captions\n" }
    let(:output) { "WEBVTT\n\n1\n00:00:03.498 --> 00:00:05.000\n- Example Captions" }
    it 'converts SRT format captions into VTT captions' do
      expect(SupplementalFile.convert_from_srt(input)).to eq output
    end
  end

  describe '.segment_transcript' do
    subject { SupplementalFile.segment_transcript(file.file) }

    context 'plain text' do
      let(:file) { FactoryBot.create(:supplemental_file, file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'chunk_test.txt'), 'text/plain')) }
      it 'splits the text by paragraph' do
        expect(subject).to be_a Array
        expect(subject.length).to eq 11
        expect(subject.all? { |s| s.is_a?(String) }).to eq true
        expect(subject[3]).to include "The Emigrant. Crossing the Alleghanies. The boundless Wilder- ness. The Hut on the Holston. Life's Necessaries."
      end
    end

    context 'docx' do
      let(:file) { FactoryBot.create(:supplemental_file, file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'chunk_test.docx'), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')) }
      it 'splits the text by paragraph' do
        expect(subject).to be_a Array
        expect(subject.length).to eq 11
        expect(subject.all? { |s| s.is_a?(String) }).to eq true
        expect(subject[3]).to include "The Emigrant. Crossing the Alleghanies. The boundless Wilder- ness. The Hut on the Holston. Life's Necessaries."
      end
    end

    context 'vtt' do
      let(:file) { FactoryBot.create(:supplemental_file, file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'chunk_test.vtt'), 'text/vtt')) }
      let(:parsed_text) { [
        "00:00:01.200 --> 00:00:21.000 [music]",
        "00:00:22.200 --> 00:00:26.600 Just before lunch one day, a puppet show was put on at school.",
        '00:00:26.700 --> 00:00:31.500 It was called "Mister Bungle Goes to Lunch".',
        "00:00:31.600 --> 00:00:34.500 It was fun to watch.",
        "00:00:36.100 --> 00:00:41.300 In the puppet show, Mr. Bungle came to the boys' room on his way to lunch.",
        "00:00:41.400 --> 00:00:46.200 He looked at his hands. His hands were dirty and his hair was messy.",
        "00:00:46.300 --> 00:00:51.100 But Mr. Bungle didn't stop to wash his hands or comb his hair.",
        "00:00:51.200 --> 00:00:54.900 He went right to lunch.",
        "00:00:57.900 --> 00:01:05.700 Then, instead of getting into line at the lunchroom, Mr. Bungle pushed everyone aside and went right to the front.",
        "00:01:06.000 --> 00:01:11.800 Even though this made the children laugh, no one thought that was a fair thing to do."
      ] }
      
      it 'splits the text by time cue' do
        expect(subject).to match_array parsed_text
      end
    end

    context 'srt' do
      let(:file) { FactoryBot.create(:supplemental_file, file: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'chunk_test.srt'), 'text/srt')) }
      it 'splits the text by time cue' do
        expect(subject).to be_a Array
        expect(subject.length).to eq 10
        expect(subject.all? { |s| s.is_a?(String) }).to eq true
        expect(subject[0]).to eq "00:00:01,200 --> 00:00:21,000 [music]"
      end
    end
  end
end
