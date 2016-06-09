require 'spec_helper'

RSpec.describe PlaylistsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/playlists').to route_to('playlists#index')
    end

    it 'routes to #new' do
      expect(get: '/playlists/new').to route_to('playlists#new')
    end

    it 'routes to #show' do
      expect(get: '/playlists/1').to route_to('playlists#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/playlists/1/edit').to route_to('playlists#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/playlists').to route_to('playlists#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/playlists/1').to route_to('playlists#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/playlists/1').to route_to('playlists#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/playlists/1').to route_to('playlists#destroy', id: '1')
    end
  end
end
