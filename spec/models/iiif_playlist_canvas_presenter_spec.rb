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

describe IiifPlaylistCanvasPresenter do
  let(:media_object) { FactoryBot.build(:media_object, visibility: 'private') }
  let(:derivative) { FactoryBot.build(:derivative) }
  let(:master_file) { FactoryBot.build(:master_file, media_object: media_object, derivatives: [derivative]) }
  let(:playlist_item) { FactoryBot.build(:playlist_item, clip: playlist_clip) }
  let(:playlist_clip) { FactoryBot.build(:avalon_clip, master_file: master_file) }
  let(:stream_info) { master_file.stream_details }
  let(:presenter) { described_class.new(playlist_item: playlist_item, stream_info: stream_info, position: 1) }

  describe '#to_s' do
    it 'returns the playlist_item label' do
      expect(presenter.to_s).to eq playlist_item.title
    end

    context 'when a user does not have access to a restricted item' do
      let(:presenter) { described_class.new(playlist_item: playlist_item, stream_info: stream_info, cannot_read_item: true) }

      it 'return "Restricted item"' do
        expect(presenter.to_s).to eq "Restricted item"
      end
    end

    context 'when an item has been deleted' do
      let(:master_file) { nil }
      let(:stream_info) { nil }

      it 'returns "Deleted item"' do
        expect(presenter.to_s).to eq "Deleted item"
      end
    end
  end

  describe '#auth_service' do
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

      it 'handles item start and end time' do
        expect(subject.url).to include("t=#{playlist_item.start_time / 1000},#{playlist_item.end_time / 1000}")
      end

      it 'has height and width' do
        expect(subject.width).to eq 1280
        expect(subject.height).to eq 40
      end
    end

    context 'when video file' do
      it 'has format' do
        expect(subject.format).to eq "application/x-mpegURL"
      end

      it 'handles item start and end time' do
        expect(subject.url).to include("#t=#{playlist_item.start_time / 1000},#{playlist_item.end_time / 1000}")
      end

      it 'has height and width' do
        expect(subject.width).to eq 1024
        expect(subject.height).to eq 768
      end
    end

    context 'when a user does not have access to a restricted item' do
      let(:presenter) { described_class.new(playlist_item: playlist_item, stream_info: stream_info, cannot_read_item: true) }

      it 'does not serialize the content' do
        expect(presenter.display_content).to be_nil
      end
    end

    context 'when an item has been deleted' do
      let(:master_file) { nil }
      let(:stream_info) { nil }

      it 'does not serialize the content' do
        expect(presenter.display_content).to be_nil
      end
    end
  end

  describe '#annotation_content' do
    subject { presenter.annotation_content }

    context 'item has markers and no captions' do
      let(:marker) { FactoryBot.create(:avalon_marker) }
      let(:playlist_item) { FactoryBot.build(:playlist_item, clip: playlist_clip, marker: [marker]) }

      it "serializes playlist markers as iiif annotations" do
        expect(subject).to all be_a(IIIFManifest::V3::AnnotationContent)
        expect(subject.length).to eq 1
      end

      it "includes marker label" do
        expect(subject.first.value).to eq marker.title
      end

      it "includes marker start_time" do
        expect(subject.first.media_fragment).to eq "t=#{marker.start_time}"
      end

      it "includes 'highlighting' motivation" do
        expect(subject.first.motivation).to eq 'highlighting'
      end
    end

    context 'item has captions and no markers' do
      let(:caption_file) { FactoryBot.create(:supplemental_file, :with_caption_file, :with_caption_tag) }
      let(:master_file) { FactoryBot.create(:master_file, :with_captions, media_object: media_object, derivatives: [derivative], supplemental_files: [caption_file]) }

      it "serializes captions as iiif annotations" do
        expect(subject).to all be_a(IIIFManifest::V3::AnnotationContent)
        expect(subject.length).to eq 2
      end

      it "includes paths to supplemental and legacy caption files" do
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{caption_file.id}\/captions/ }).to eq true
        expect(subject.any? { |content| content.body_id =~ /master_files\/#{master_file.id}\/captions/ }).to eq true
      end

      it "includes 'supplementing' motivation" do
        expect(subject.any? { |content| content.motivation =~ /supplementing/ }).to eq true
      end
    end

    context 'item has captions and markers' do
      let(:marker) { FactoryBot.create(:avalon_marker) }
      let(:playlist_item) { FactoryBot.build(:playlist_item, clip: playlist_clip, marker: [marker]) }
      let(:caption_file) { FactoryBot.create(:supplemental_file, :with_caption_file, :with_caption_tag) }
      let(:master_file) { FactoryBot.create(:master_file, :with_captions, media_object: media_object, derivatives: [derivative], supplemental_files: [caption_file]) }

      it "serializes captions as iiif annotations" do
        expect(subject).to all be_a(IIIFManifest::V3::AnnotationContent)
        expect(subject.length).to eq 3
      end

      it "includes marker label" do
        expect(subject.any? { |content| content.value =~ /#{marker.title}/ }).to eq true
      end

      it "includes marker start_time" do
        expect(subject.any? { |content| content.media_fragment =~ /t=#{marker.start_time}/ }).to eq true
      end

      it "includes paths to supplemental and legacy caption files" do
        expect(subject.any? { |content| content.body_id =~ /supplemental_files\/#{caption_file.id}\/captions/ }).to eq true
        expect(subject.any? { |content| content.body_id =~ /master_files\/#{master_file.id}\/captions/ }).to eq true
      end

      it "includes 'highlighting' motivation" do
        expect(subject.any? { |content| content.motivation =~ /highlighting/ }).to eq true
      end

      it "includes 'supplementing' motivation" do
        expect(subject.any? { |content| content.motivation =~ /supplementing/ }).to eq true
      end
    end

    context 'when a user does not have access to a restricted item' do
      let(:presenter) { described_class.new(playlist_item: playlist_item, stream_info: stream_info, cannot_read_item: true) }

      it 'does not serialize the content' do
        expect(presenter.annotation_content).to be_nil
      end
    end

    context 'when an item has been deleted' do
      let(:master_file) { nil }
      let(:stream_info) { nil }

      it 'does not serialize the content' do
        expect(presenter.annotation_content).to be_nil
      end
    end
  end

  describe '#range' do
    subject { presenter.range }

    it 'generates the clip range' do
    	expect(subject.label.to_s).to eq "{\"none\"=>[\"#{playlist_item.title}\"]}"
    	expect(subject.items.size).to eq 1
    	expect(subject.items.first).to be_a IiifPlaylistCanvasPresenter
      expect(subject.items.first.media_fragment).to eq "t=#{playlist_item.start_time / 1000},#{playlist_item.end_time / 1000}"
    end
  end

  describe '#part_of' do
    subject { presenter.part_of }

    it 'references the parent media object manifest' do
      expect(subject.first['type']).to eq 'manifest'
      expect(subject.any? { |po| po["@id"] =~ /media_objects\/#{media_object.id}\/manifest/ }).to eq true
    end
  end

  describe '#placeholder_contetnt' do
    subject { presenter.placeholder_content }

    it 'does not generate a placeholder for non-restricted items' do
      expect(subject).to be_nil
    end

    context 'when a user does not have access to a restricted item' do
      let(:presenter) { described_class.new(playlist_item: playlist_item, stream_info: stream_info, cannot_read_item: true) }

      it 'generates placeholder canvas' do
        expect(subject).to be_present
        expect(subject.format).to eq "text/plain"
        expect(subject.type).to eq "Text"
        expect(subject.label).to eq I18n.t('playlist.restrictedText')
      end
    end

    context 'when an item has been deleted' do
      let(:master_file) { nil }
      let(:stream_info) { nil }

      it 'generates placeholder canvas' do
        expect(subject).to be_present
        expect(subject.format).to eq "text/plain"
        expect(subject.type).to eq "Text"
        expect(subject.label).to eq I18n.t('playlist.deletedText')
      end
    end

    context 'when an item has no derivatives' do
      let(:master_file) { FactoryBot.build(:master_file, media_object: media_object) }

      it 'generates placeholder canvas' do
        expect(subject).to be_present
        expect(subject.format).to eq "text/plain"
        expect(subject.type).to eq "Text"
        expect(subject.label).to eq I18n.t('errors.missing_derivatives_error') % [Settings.email.support, Settings.email.support]
      end
    end
  end

  describe "#item_metadata" do
    subject { presenter.item_metadata }

    it 'returns the title, date, and main contributor of the parent item' do
      expect(subject.first['label']).to eq({ 'en' => ['Title'] })
      expect(subject.first['value']).to eq({ 'en' => ["<a href='#{Rails.application.routes.url_helpers.media_object_url(media_object)}'>#{media_object.title}</a>"] })
      expect(subject.second['label']).to eq({ 'en' => ['Date'] })
      expect(subject.second['value']).to eq({ 'en' => [media_object.date_issued] })
      expect(subject.last['label']).to eq({ 'en' => ['Main Contributor'] })
      expect(subject.last['value']).to eq({ 'en' => media_object.creator })
    end
  end

  describe "#description" do
    subject { presenter.description }

    it 'returns the description of the playlist item' do
      expect(subject).to eq playlist_item.comment
    end
  end

  describe "#homepage" do
    subject { presenter.homepage }
    let(:playlist_item) { FactoryBot.create(:playlist_item, clip: playlist_clip) }
    let(:playlist_clip) { FactoryBot.create(:avalon_clip, master_file: master_file) }

    it "it references the item's position within the playlist" do
      expect(subject.first['@id']).to eq "#{Rails.application.routes.url_helpers.playlist_url(playlist_item.playlist_id)}?position=1"
      expect(subject.first['label']).to be_present
      expect(subject.first['type']).to be_present
    end
  end
end
