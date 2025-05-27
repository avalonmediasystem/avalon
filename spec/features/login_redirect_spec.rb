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

describe 'Login Redirects' do
  let(:user) { FactoryBot.create(:user, :with_identity) }

  describe '/media_objects/:id' do
    let(:media_object) { FactoryBot.create(:fully_searchable_media_object) }
    let!(:master_file) { FactoryBot.create(:master_file, :with_derivative, media_object: media_object) }

    it 'redirects to item page' do
      visit media_object_path(media_object)
      visit hls_manifest_master_file_path(media_object.sections.first, "high")
      sign_in user
      expect(page.current_path).to eq media_object_path(media_object)
    end

    context 'visiting item after accessing restricted page' do
      it 'redirects to item page' do
        visit playlists_path
        visit media_object_path(media_object)
        sign_in user
        expect(page.current_path).to eq media_object_path(media_object)
      end
    end
  end

  describe '/collection/:id' do
    let(:collection) { FactoryBot.create(:collection) }
    let(:media_object) { FactoryBot.create(:fully_searchable_media_object, collection: collection) }

    it 'redirects to collection page' do
      visit collections_path(collection, format: :html)
      visit poster_collection_path(collection)
      sign_in user
      expect(page.current_path).to eq collections_path(collection, format: :html)
    end
  end
end
