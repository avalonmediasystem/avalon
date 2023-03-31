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
  let(:media_object) { FactoryBot.build(:media_object) }
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
end
