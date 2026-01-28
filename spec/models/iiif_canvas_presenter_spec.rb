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

  describe "#to_s" do
    subject { presenter.to_s }

    context 'single-section item' do
      it 'prioritizes MediaObject#title for section title' do
        expect(subject).to eq master_file.structure_title
        expect(subject).to eq media_object.title
        expect(subject).to_not eq master_file.display_title
      end
    end

    context 'multi-section item' do
      let(:second) { FactoryBot.build(:master_file, media_object: media_object, derivatives: [derivative]) }

      before :each do
        media_object.sections = [master_file, second]
        media_object.save!
      end

      it 'prioritizes MasterFile#display_title for section titles' do
        expect(subject).to eq master_file.structure_title
        expect(subject).to eq master_file.display_title
        expect(subject).to_not eq media_object.title
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

      it 'has height and width' do
        expect(subject.width).to eq 1280
        expect(subject.height).to eq 40
      end

      it 'has thumbnail' do
        expect(subject.thumbnail.first[:id]).to start_with "http://test.host/assets/audio_icon"
      end

      context 'with mp3 file' do
        let(:mp3_url) { 'https://streaming.example.com/dir/file.mp3' }
        let(:derivative) { FactoryBot.build(:derivative, hls_url: mp3_url, mime_type: 'audio/mpeg' ) }

        it 'has format' do
          expect(subject.format).to eq 'audio/mpeg'
        end

        it 'has progressive download url' do
          expect(subject.url).to eq mp3_url
        end
      end
    end

    context 'when video file' do
      it 'has format' do
        expect(subject.format).to eq "application/x-mpegURL"
      end

      it 'has height and width' do
        expect(subject.width).to eq 1024
        expect(subject.height).to eq 768
      end

      it 'has thumbnail' do
        expect(subject.thumbnail.first[:id]).to eq "http://test.host/master_files/#{master_file.id}/thumbnail"
      end

      context 'with mp4 file' do
        let(:mp4_url) { 'https://streaming.example.com/dir/file.mp4' }
        let(:derivative) { FactoryBot.build(:derivative, hls_url: mp4_url, mime_type: 'video/mp4' ) }

        it 'has format' do
          expect(subject.format).to eq 'video/mp4'
        end

        it 'has progressive download url' do
          expect(subject.url).to eq mp4_url
        end
      end
    end
  end

  describe '#range' do
    let(:structure_xml) { '<?xml version="1.0"?><Item label="Test"><Div label="Div 1"><Span label="Span 1" begin="00:00:00.000" end="00:00:01.235"/></Div></Item>' }

    subject { presenter.range }

    before do
      master_file.structuralMetadata.content = structure_xml
    end

    it 'converts stored xml into IIIF ranges with canvas reference in root range' do
      expect(subject.label.to_s).to eq '{"none" => ["Test"]}'
      expect(subject.items.size).to eq 2
      expect(subject.items.first).to be_a IiifCanvasPresenter
      expect(subject.items.first.media_fragment).to eq "t=0,#{master_file.duration.to_f/1000}"
      expect(subject.items.second.label.to_s).to eq '{"none" => ["Div 1"]}'
      expect(subject.items.second.items.size).to eq 1
      expect(subject.items.second.items.first.label.to_s).to eq '{"none" => ["Span 1"]}'
      expect(subject.items.second.items.first.items.size).to eq 1
      expect(subject.items.second.items.first.items.first).to be_a IiifCanvasPresenter
      expect(subject.items.second.items.first.items.first.media_fragment).to eq 't=0.0,1.235'
    end

    context 'with no structural metadata' do
      context 'master file with title' do
        let(:structure_xml) { "" }
        let(:master_file) { FactoryBot.create(:master_file, title: "video.mp4", media_object: media_object, derivatives: [derivative]) }

        it 'autogenerates a basic range with structure_title as label' do
        	expect(subject.label.to_s).to eq "{\"none\" => [\"#{master_file.structure_title}\"]}"
        	expect(subject.items.size).to eq 1
        	expect(subject.items.first).to be_a IiifCanvasPresenter
          expect(subject.items.first.media_fragment).to eq "t=0,#{master_file.duration.to_f/1000}"
        end
      end

      context 'master file without title' do
        let(:structure_xml) { "" }

        it 'autogenerates a basic range with media_object.title as label' do
        	expect(subject.label.to_s).to eq "{\"none\" => [\"#{media_object.title}\"]}"
        	expect(subject.items.size).to eq 1
        	expect(subject.items.first).to be_a IiifCanvasPresenter
          expect(subject.items.first.media_fragment).to eq "t=0,#{master_file.duration.to_f/1000}"
        end
      end
    end

    context 'with childless divs' do
      context 'without spans' do
        let(:structure_xml) { '<?xml version="1.0"?><Item label="Test"><Div label="Div 1"><Div label="Div 2"><Div label="Div 3"/></Div></Div></Item>' }

        it 'generates a canvas reference in the root range' do
          expect(subject.label.to_s).to eq '{"none" => ["Test"]}'
          expect(subject.items.size).to eq 2
          expect(subject.items.first).to be_a IiifCanvasPresenter
          expect(subject.items.first.media_fragment).to eq "t=0,#{master_file.duration.to_f/1000}"
          expect(subject.items.second.label.to_s).to eq '{"none" => ["Div 1"]}'
          expect(subject.items.second.items.size).to eq 1
          expect(subject.items.second.items.first.label.to_s).to eq '{"none" => ["Div 2"]}'
          expect(subject.items.second.items.first.items.size).to eq 1
          expect(subject.items.second.items.first.items.first.label.to_s).to eq '{"none" => ["Div 3"]}'
          expect(subject.items.second.items.first.items.first.items.size).to eq 0
        end
      end

      context 'with spans' do
        let(:structure_xml) { '<?xml version="1.0"?><Item label="Test"><Div label="Div 1"><Div label="Div 2"><Div label="Div 3"/></Div><Span label="Span 1" begin="00:00:00.000" end="00:00:01.235"/></Div></Item>' }

        it 'generates a canvas reference in the root range' do
          expect(subject.label.to_s).to eq '{"none" => ["Test"]}'
          expect(subject.items.size).to eq 2
          expect(subject.items.first).to be_a IiifCanvasPresenter
          expect(subject.items.first.media_fragment).to eq "t=0,#{master_file.duration.to_f/1000}"
          expect(subject.items.second.label.to_s).to eq '{"none" => ["Div 1"]}'
          expect(subject.items.second.items.size).to eq 2
          expect(subject.items.second.items.first.label.to_s).to eq '{"none" => ["Div 2"]}'
          expect(subject.items.second.items.first.items.size).to eq 1
          expect(subject.items.second.items.first.items.first.label.to_s).to eq '{"none" => ["Div 3"]}'
          expect(subject.items.second.items.first.items.first.items.size).to eq 0
          expect(subject.items.second.items.second.label.to_s).to eq '{"none" => ["Span 1"]}'
          expect(subject.items.second.items.second.items.size).to eq 1
          expect(subject.items.second.items.second.items.first).to be_a IiifCanvasPresenter
          expect(subject.items.second.items.second.items.first.media_fragment).to eq 't=0.0,1.235'
        end
      end

      context 'with nested divs and spans' do
        let(:structure_xml) { '<?xml version="1.0"?><Item label="Test"><Div label="Div 1"><Span label="Span 1" begin="00:00:00.000" end="00:00:01.235"><Div label="Div 2"><Div label="Div 3"/></Div><Span label="Span 2" begin="00:00:00.500" end="00:00:01.000"/></Span><Span label="Span 3" begin="00:00:01.236" end="00:00:02.235"/></Div></Item>' }
        
        it 'generates a canvas reference in the root range' do
          expect(subject.label.to_s).to eq '{"none" => ["Test"]}'
          expect(subject.items.size).to eq 2
          item = subject.items.first
          expect(item).to be_a IiifCanvasPresenter
          expect(item.media_fragment).to eq "t=0,#{master_file.duration.to_f/1000}"
          top_level_div = subject.items.second
          expect(top_level_div.label.to_s).to eq '{"none" => ["Div 1"]}'
          expect(top_level_div.items.size).to eq 2
          parent_span = top_level_div.items.first
          expect(parent_span.label.to_s).to eq '{"none" => ["Span 1"]}'
          expect(parent_span.items.first).to be_a IiifCanvasPresenter
          expect(parent_span.items.size).to eq 3
          expect(parent_span.items.first.media_fragment).to eq 't=0.0,1.235'
          child_div = parent_span.items.second
          expect(child_div.label.to_s).to eq '{"none" => ["Div 2"]}'
          expect(child_div.items.size).to eq 1
          grandchild_div = child_div.items.first
          expect(grandchild_div.label.to_s).to eq '{"none" => ["Div 3"]}'
          expect(grandchild_div.items.size).to eq 0
          child_span = parent_span.items.third
          expect(child_span.label.to_s).to eq '{"none" => ["Span 2"]}'
          expect(child_span.items.size).to eq 1
          expect(child_span.items.first).to be_a IiifCanvasPresenter
          expect(child_span.items.first.media_fragment).to eq 't=0.5,1.0'
          sibling_span = subject.items.second.items.second
          expect(sibling_span.label.to_s).to eq '{"none" => ["Span 3"]}'
          expect(sibling_span.items.size).to eq 1
          expect(sibling_span.items.first).to be_a IiifCanvasPresenter
          expect(sibling_span.items.first.media_fragment).to eq 't=1.236,2.235'
        end
      end
    end
  end

  describe '#placeholder_content' do
    subject { presenter.placeholder_content }

    context 'when master file has derivatives' do
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

    context 'when master file does not have derivatives' do
      let(:master_file) { FactoryBot.build(:master_file, :completed_processing, media_object: media_object) }

      it 'has format' do
        expect(subject.format).to eq "text/plain"
      end

      it 'has type' do
        expect(subject.type).to eq "Text"
      end

      it 'has label' do
        expect(subject.label).to eq I18n.t('errors.missing_derivatives_error') % [Settings.email.support, Settings.email.support]
      end

      it 'has height and width' do
        expect(subject.width).to eq 1280
        expect(subject.height).to eq 720
      end
    end

    context 'when master file is processing' do
      let(:master_file) { FactoryBot.build(:master_file, media_object: media_object) }

      it 'has format' do
        expect(subject.format).to eq "text/plain"
      end

      it 'has type' do
        expect(subject.type).to eq "Text"
      end

      it 'has label' do
        expect(subject.label).to eq I18n.t('media_object.conversion_msg')
      end

      it 'has height and width' do
        expect(subject.width).to eq 1280
        expect(subject.height).to eq 720
      end
    end
  end

  describe 'Supplemental file handling' do
    let(:master_file) { FactoryBot.create(:master_file, :with_waveform, supplemental_files_json: supplemental_files_json, media_object: media_object, derivatives: [derivative]) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
    let(:transcript_file) { FactoryBot.create(:supplemental_file, :with_transcript_tag, :with_transcript_file) }
    let(:caption_file) { FactoryBot.create(:supplemental_file, :with_caption_file, :with_caption_tag) }
    let(:description_file) { FactoryBot.create(:supplemental_file, :with_description_file, :with_description_tag) }
    let(:private_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['transcript', 'private']) }
    let(:supplemental_files) { [supplemental_file, transcript_file, caption_file, description_file, private_file] }
    let(:supplemental_files_json) { supplemental_files.map(&:to_global_id).map(&:to_s).to_s }

    describe '#sequence_rendering' do
      subject { presenter.sequence_rendering }

      it 'includes supplemental files, captions, and descriptions' do
        expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{supplemental_file.id}/ }).to eq true
        expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{caption_file.id}/ }).to eq true
        expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{description_file.id}/ }).to eq true
      end

      it 'does not include waveform, transcripts, or private files' do
        expect(subject.any? { |rendering| rendering["label"]["en"] == ["waveform.json"] }).to eq false
        expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{transcript_file.id}/ }).to eq false
        expect(subject.any? { |rendering| rendering["@id"] =~ /supplemental_files\/#{private_file.id}/ }).to eq false
      end
    end

    describe '#annotation_content' do
      subject { presenter.annotation_content }

      it 'converts file metadata into IIIF Manifest SupplementingContent' do
        expect(subject).to all be_a(IIIFManifest::V3::AnnotationContent)
      end

      it "includes 'supplementing' motivation" do
        expect(subject.first.motivation).to eq 'supplementing'
      end

      it 'includes transcript, caption, and description files' do
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{transcript_file.id}/ }).to eq true
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{caption_file.id}/ }).to eq true
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{description_file.id}/ }).to eq true
      end

      it 'does not include private files' do
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{private_file.id}/ }).to eq false
      end

      it 'includes original filenames' do
        expect(subject.any? { |content| content.label['none'] == [caption_file.file.filename.to_s] }).to eq true
      end

      it 'includes label' do
        expect(subject.any? { |content| content.label['eng'] == [caption_file.label] }).to eq true
      end

      it 'differentiates between transcript, caption, and description files' do
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{transcript_file.id}\/transcripts/ }).to eq true
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{caption_file.id}\/captions/ }).to eq true
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{description_file.id}\/description/ }).to eq true
      end

      it 'does not add " (machine generated)" to label of non-generated files' do
        expect(subject.any? { |content| content.label['eng'][0] =~ /#{transcript_file.label} \(machine generated\)/ }).to eq false
        expect(subject.any? { |content| content.label['eng'][0] =~ /#{caption_file.label} \(machine generated\)/ }).to eq false
      end

      it 'does not include generic supplemental files or waveform' do
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{supplemental_file.id}/ }).to eq false
        expect(subject.any? { |content| content.label == { "en" => ["waveform.json"] } }).to eq false
      end

      it 'does not include master file captions url when legacy captions are not present' do
        expect(subject.any? { |content| content.body_id =~ /master_files\/#{master_file.id}\/captions/ }).to eq false
      end

      context 'srt files' do
        let(:srt_caption_file) { FactoryBot.create(:supplemental_file, :with_caption_srt_file, :with_caption_tag) }
        let(:srt_transcript_file) { FactoryBot.create(:supplemental_file, :with_caption_srt_file, :with_transcript_tag) }
        let(:srt_description_file) { FactoryBot.create(:supplemental_file, :with_description_srt_file, :with_description_tag) }
        let(:supplemental_files) { [transcript_file, caption_file, srt_caption_file, srt_transcript_file, description_file, srt_description_file] }
        it 'sets caption and description format to "text/vtt"' do
          captions = subject.select { |s| s.body_id.include?('captions') }
          descriptions = subject.select { |s| s.body_id.include?('descriptions') }
          expect(captions.none? { |content| content.format == 'text/srt' }).to eq true
          expect(captions.all? { |content| content.format == 'text/vtt' }).to eq true
          expect(descriptions.none? { |content| content.format == 'text/srt' }).to eq true
          expect(descriptions.all? { |content| content.format == 'text/vtt' }).to eq true
        end
        it 'sets other formats to the original file content_type' do
          supplemental_files = subject.reject { |s| s.body_id.include?('captions') }
          expect(supplemental_files[0].format).to eq transcript_file.file.content_type
          expect(supplemental_files[1].format).to eq srt_transcript_file.file.content_type
        end
      end

      context 'legacy master file captions' do
        let(:master_file) { FactoryBot.create(:master_file, :with_waveform, :with_captions, supplemental_files_json: supplemental_files_json, media_object: media_object, derivatives: [derivative]) }

        it 'does not include the master file captions' do
          expect(subject.any? { |content| content.body_id =~ /master_files\/#{master_file.id}\/captions/ }).to eq false
        end
      end

      context 'machine generated transcript' do
        let(:transcript_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['transcript', 'machine_generated']) }

        it "adds '(machine generated)' to the label" do
          expect(subject.any? { |content| content.label['eng'][0] =~ /#{transcript_file.label} \(machine generated\)/ }).to eq true
        end
      end

      context 'caption being treated as a transcript' do
        let(:caption_file) { FactoryBot.create(:supplemental_file, :with_caption_file, tags: ['caption', 'transcript']) }
        let(:srt_caption_file) { FactoryBot.create(:supplemental_file, :with_caption_srt_file, tags: ['caption', 'transcript']) }
        let(:supplemental_files) { [caption_file, srt_caption_file] }

        it 'returns a caption entry and a transcript entry with proper formats' do
          captions = subject.select { |s| s.body_id.include?('captions') }
          transcripts = subject.select { |s| s.body_id.include?('transcripts') }
          expect(captions.count).to eq 2
          expect(transcripts.count).to eq 2
          expect(captions.all? { |content| content.format == 'text/vtt' }).to eq true
          expect(transcripts.any? { |content| content.format == 'text/vtt' }).to eq true
          expect(transcripts.any? { |content| content.format == 'text/srt' }).to eq true
        end
      end
    end
  end

  describe '#see_also' do
    let(:master_file) { FactoryBot.build(:master_file, :with_waveform, supplemental_files_json: supplemental_files_json, media_object: media_object, derivatives: [derivative]) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
    let(:transcript_file) { FactoryBot.create(:supplemental_file, :with_transcript_tag, :with_transcript_file) }
    let(:caption_file) { FactoryBot.create(:supplemental_file, :with_caption_file, tags: ['caption', 'machine_generated']) }
    let(:description_file) { FactoryBot.create(:supplemental_file, :with_description_file, :with_description_tag) }
    let(:supplemental_files) { [supplemental_file, transcript_file, caption_file] }
    let(:supplemental_files_json) { supplemental_files.map(&:to_global_id).map(&:to_s).to_s }

    subject { presenter.see_also }

    it 'includes waveform' do
      expect(subject.any? { |sa| sa["label"]["en"] == ["waveform.json"] }).to eq true
    end

    it 'does not include supplemental files, transcripts, captions, or descriptions' do
      expect(subject.any? { |sa| sa["@id"] =~ /supplemental_files\/#{supplemental_file.id}/ }).to eq false
      expect(subject.any? { |sa| sa["@id"] =~ /supplemental_files\/#{transcript_file.id}/ }).to eq false
      expect(subject.any? { |sa| sa["@id"] =~ /supplemental_files\/#{caption_file.id}/ }).to eq false
      expect(subject.any? { |sa| sa["@id"] =~ /supplemental_file\/#{description_file.id}/ }).to eq false
    end
  end

  describe '#service' do
    subject { presenter.service }

    it 'includes the content search service' do
      expect(subject.any? { |content| content['@id'] =~ /master_files\/#{master_file.id}\/search/ }).to eq true
      expect(subject.first["type"]).to eq 'SearchService2'
    end
  end
end
