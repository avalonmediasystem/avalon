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

RSpec.describe SupplementalFilesController, type: :controller do
  it_behaves_like "a nested controller for", MasterFile
  it_behaves_like "a nested controller for", MediaObject

  describe 'captions endpoint for MasterFile' do
    let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_caption_file, :with_caption_tag) }
    # This should return the minimal set of values that should be in the session
    # in order to pass any filters (e.g. authentication) defined in
    # SupplementalFilesController. Be sure to keep this updated too.
    let(:valid_session) { {} }


    describe 'security' do
      let(:master_file) { FactoryBot.create(:master_file, :with_media_object, supplemental_files: [supplemental_file]) }

      context 'with unauthenticated user' do
        it 'should return 401' do
          expect(get :captions, params: { master_file_id: master_file.id, id: supplemental_file.id }).to have_http_status(401)
        end
      end
      context 'with end-user without permissions' do
        before do
          login_as :user
        end
        it 'should return 401' do
          expect(get :captions, params: { master_file_id: master_file.id, id: supplemental_file.id }).to have_http_status(401)
        end
      end
    end

    describe "GET #captions" do
      let(:public_media_object) { FactoryBot.create(:fully_searchable_media_object) }
      let(:master_file) { FactoryBot.create(:master_file, media_object: public_media_object, supplemental_files: [supplemental_file]) }
      before { allow(Settings.supplemental_files).to receive(:proxy).and_return(true) }

      it "returns the caption file content" do
        get :captions, params: {  master_file_id: master_file.id, id: supplemental_file.id }, session: valid_session
        expect(response).to have_http_status(200)
        expect(response.header["Content-Type"]).to eq 'text/vtt'
        expect(response.body).to eq supplemental_file.file.download
      end

      context 'with SRT caption' do
        let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_caption_tag, :with_caption_srt_file) }
        let(:file) { Rails.root.join('spec', 'fixtures', 'captions.srt')}
        it 'returns the caption file content in VTT format' do
          get :captions, params: {  master_file_id: master_file.id, id: supplemental_file.id }, session: valid_session
          expect(response).to have_http_status(200)
          expect(response.header["Content-Type"]).to eq 'text/vtt'
          expect(response.body).to eq SupplementalFile.convert_from_srt(File.read(file))
        end
      end
    end
  end
end
