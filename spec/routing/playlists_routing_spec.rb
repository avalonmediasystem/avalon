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

require "rails_helper"

RSpec.describe PlaylistsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/playlists").to route_to("playlists#index")
    end

    it "routes to #new" do
      expect(:get => "/playlists/new").to route_to("playlists#new")
    end

    it "routes to #show" do
      expect(:get => "/playlists/1").to route_to("playlists#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/playlists/1/edit").to route_to("playlists#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/playlists").to route_to("playlists#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/playlists/1").to route_to("playlists#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/playlists/1").to route_to("playlists#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/playlists/1").to route_to("playlists#destroy", :id => "1")
    end

    it "routes to #manifest" do
      expect(:get => "/playlists/1/manifest.json").to route_to("playlists#manifest", :id => "1", format: "json")
    end

    it "routes to #refresh_info" do
      expect(:get => "/playlists/1/refresh_info").to route_to("playlists#refresh_info", :id => "1")
    end

    it "routes to #paged_index" do
      expect(:post => "/playlists/paged_index").to route_to("playlists#paged_index")
    end

    it "routes to #regenerate_access_token" do
      expect(:patch => "/playlists/1/regenerate_access_token").to route_to("playlists#regenerate_access_token", :id => "1")
    end

    it "routes to #update_multiple" do
      expect(:patch => "/playlists/1/update_multiple").to route_to("playlists#update_multiple", :id => "1")
    end

    it "routes to #duplicate" do
      expect(:post => "/playlists/duplicate").to route_to("playlists#duplicate")
    end
  end
end
