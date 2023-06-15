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

describe IiifCanvasPresenter do
  let(:media_object) { FactoryBot.build(:media_object, visibility: 'private') }
  let(:derivative) { FactoryBot.build(:derivative) }
  let(:master_file) { FactoryBot.build(:master_file, media_object: media_object, derivatives: [derivative]) }
  let(:stream_info) { master_file.stream_details }
  let(:presenter) { described_class.new(master_file: master_file, stream_info: stream_info) }

  context 'auth_service' do
    subject { presenter.display_content.first.auth_service }

    it 'provides a cookie auth service' do
      expect(subject[:@id]).to eq Rails.application.routes.url_helpers.new_user_session_url(login_popup: 1)
    end

    it 'provides a token service' do
      token_service = subject[:service].find { |s| s[:@type] == "AuthTokenService1"}
      expect(token_service[:@id]).to eq Rails.application.routes.url_helpers.iiif_auth_token_url(id: master_file.id)
    end

    it 'provides a logout service' do
      logout_service = subject[:service].find { |s| s[:@type] == "AuthLogoutService1"}
      expect(logout_service[:@id]).to eq Rails.application.routes.url_helpers.destroy_user_session_url
    end

    context 'when public media object' do
      let(:media_object) { FactoryBot.build(:media_object, visibility: 'public') }

      it "does not provide an auth service" do
        expect(presenter.display_content.first.auth_service).to be_nil
      end
    end
  end

  describe '#display_content' do
    subject { presenter.display_content.first }

    context 'when audio file' do
      let(:master_file) { FactoryBot.build(:master_file, :audio, media_object: media_object, derivatives: [derivative]) }

      it 'has format' do
        expect(subject.format).to eq "application/x-mpegURL"
      end
    end

    context 'when video file' do
      it 'has format' do
        expect(subject.format).to eq "application/x-mpegURL"
      end
    end
  end

  describe '#range' do
    let(:structure_xml) { '<?xml version="1.0"?><Item label="Test"><Div label="Div 1"><Span label="Span 1" begin="00:00:00.000" end="00:00:01.235"/></Div></Item>' }

    subject { presenter.range }

    before do
      master_file.structuralMetadata.content = structure_xml
    end

    it 'converts stored xml into IIIF ranges' do
      expect(subject.label.to_s).to eq '{"none"=>["Test"]}'
      expect(subject.items.size).to eq 1
      expect(subject.items.first.label.to_s).to eq '{"none"=>["Div 1"]}'
      expect(subject.items.first.items.size).to eq 1
      expect(subject.items.first.items.first.label.to_s).to eq '{"none"=>["Span 1"]}'
      expect(subject.items.first.items.first.items.size).to eq 1
      expect(subject.items.first.items.first.items.first).to be_a IiifCanvasPresenter
      expect(subject.items.first.items.first.items.first.media_fragment).to eq 't=0.0,1.235'
    end

    context 'with no structural metadata' do
      let(:structure_xml) { "" }

      it 'autogenerates a basic range' do
      	expect(subject.label.to_s).to eq "{\"none\"=>[\"#{master_file.embed_title}\"]}"
      	expect(subject.items.size).to eq 1
      	expect(subject.items.first).to be_a IiifCanvasPresenter
        expect(subject.items.first.media_fragment).to eq 't=0,'
      end
    end
  end

  describe '#placeholder_content' do
    subject { presenter.placeholder_content }

    it 'has format' do
      expect(subject.format).to eq "image/jpeg"
    end

    it 'has type' do
      expect(subject.type).to eq "Image"
    end

    it 'has height and width' do
      expect(subject.width).to eq 1280
      expect(subject.height).to eq 720
    end
  end

  describe 'Supplemental file handling' do
    let(:master_file) { FactoryBot.build(:master_file, :with_waveform, supplemental_files_json: supplemental_files_json, media_object: media_object, derivatives: [derivative]) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
    let(:transcript_file) { FactoryBot.create(:supplemental_file, :with_transcript_tag) }
    let(:caption_file) { FactoryBot.create(:supplemental_file, :with_caption_file, tags: ['caption', 'machine_generated']) }
    let(:supplemental_files) { [supplemental_file, transcript_file, caption_file] }
    let(:supplemental_files_json) { supplemental_files.map(&:to_global_id).map(&:to_s).to_s }

    describe '#sequence_rendering' do
      subject { presenter.sequence_rendering }

      it 'includes supplemental files' do
        expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{supplemental_file.id}/ }).to eq true
      end

      it 'does not include waveform, transcripts, or captions' do
        expect(subject.any? { |rendering| rendering["label"]["en"] == ["waveform.json"] }).to eq false
        expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{transcript_file.id}/ }).to eq false
        expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{caption_file.id}/ }).to eq false
      end
    end

    describe '#supplementing_content' do
      subject { presenter.supplementing_content }

      it 'converts file metadata into IIIF Manifest SupplementingContent' do
        expect(subject).to all be_a(IIIFManifest::V3::SupplementingContent)
      end

      it 'includes transcript and caption files' do
        expect(subject.any? { |content| content.url =~ /supplemental_files\/#{transcript_file.id}/ }).to eq true
        expect(subject.any? { |content| content.url =~ /supplemental_files\/#{caption_file.id}/ }).to eq true
      end

      it 'differentiates between transcript and caption files' do
        expect(subject.any? { |content| content.url =~ /supplemental_files\/#{transcript_file.id}\/transcript/ }).to eq true
        expect(subject.any? { |content| content.url =~ /supplemental_files\/#{caption_file.id}\/caption/ }).to eq true
      end

      it 'does not include generic supplemental files or waveform' do
        expect(subject.any? { |content| content.url =~ /supplemental_files\/#{supplemental_file.id}/ }).to eq false
        expect(subject.any? { |content| content.label == { "en" => ["waveform.json"] } }).to eq false
      end
    end
  end

  describe '#see_also' do
    let(:master_file) { FactoryBot.build(:master_file, :with_waveform, supplemental_files_json: supplemental_files_json, media_object: media_object, derivatives: [derivative]) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
    let(:transcript_file) { FactoryBot.create(:supplemental_file, :with_transcript_tag) }
    let(:caption_file) { FactoryBot.create(:supplemental_file, :with_caption_file, tags: ['caption', 'machine_generated']) }
    let(:supplemental_files) { [supplemental_file, transcript_file, caption_file] }
    let(:supplemental_files_json) { supplemental_files.map(&:to_global_id).map(&:to_s).to_s }

    subject { presenter.see_also }

    it 'includes waveform' do
      expect(subject.any? { |sa| sa["label"]["en"] == ["waveform.json"] }).to eq true
    end

    it 'does not include supplemental files, transcripts, or captions' do
      expect(subject.any? { |sa| sa["@id"] =~ /supplemental_files\/#{supplemental_file.id}/ }).to eq false
      expect(subject.any? { |sa| sa["@id"] =~ /supplemental_files\/#{transcript_file.id}/ }).to eq false
      expect(subject.any? { |sa| sa["@id"] =~ /supplemental_files\/#{caption_file.id}/ }).to eq false
    end
  end
end
