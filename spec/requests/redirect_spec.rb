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

describe 'redirect', type: :request do
  it 'stores url to redirect to when unauthorized and needing to authenticate (#authorize!)' do
    get '/admin/collections'
    expect(request.env['rack.session']['user_return_to']).to eq '/admin/collections'
    expect(response).to render_template('errors/restricted_pid')
  end

  it 'stores url to redirect to when needing to authenticate (#authenticate_user!)' do
    get '/bookmarks'
    expect(request.env['rack.session']['user_return_to']).to eq '/bookmarks'
    expect(response).to render_template('errors/restricted_pid')
  end

  context 'playlists' do
    let(:playlist) { FactoryBot.create(:playlist, :with_access_token, items: [playlist_item]) }
    let(:playlist_item) { FactoryBot.create(:playlist_item, clip: clip) }
    let(:clip) { FactoryBot.create(:avalon_clip, master_file: master_file) }
    let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }
    let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'restricted') }
    let(:playlist_url) { playlist_path(playlist, token: playlist.access_token) }

    it 'stores url to redirect to when loading a playlist in case of restricted playlist items' do
      get playlist_url
      expect(request.env['rack.session']['user_return_to']).to eq playlist_url
      expect(response).to render_template('playlists/show')
    end
  end
end
