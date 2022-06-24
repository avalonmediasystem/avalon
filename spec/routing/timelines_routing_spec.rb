# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

RSpec.describe TimelinesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/timelines").to route_to("timelines#index")
    end

    it "routes to #new" do
      expect(:get => "/timelines/new").to route_to("timelines#new")
    end

    it "routes to #show" do
      expect(:get => "/timelines/1").to route_to("timelines#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/timelines/1/edit").to route_to("timelines#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/timelines").to route_to("timelines#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/timelines/1").to route_to("timelines#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/timelines/1").to route_to("timelines#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/timelines/1").to route_to("timelines#destroy", :id => "1")
    end

    it "routes to #manifest" do
      expect(:get => "/timelines/1/manifest.json").to route_to("timelines#manifest", :id => "1", format: "json")
    end

    it "routes to #manifest via POST" do
      expect(:post => "/timelines/1/manifest.json").to route_to("timelines#manifest_update", :id => "1", format: "json")
    end

    it "routes to #timeliner" do
      expect(:get => "/timeliner").to route_to("timelines#timeliner")
    end

    it "routes to #regenerate_access_token" do
      expect(:patch => "/timelines/1/regenerate_access_token").to route_to("timelines#regenerate_access_token", :id => "1")
    end

    it "routes to #duplicate" do
      expect(:post => "/timelines/duplicate").to route_to("timelines#duplicate")
    end

    it "routes to #paged_index" do
      expect(:post => "/timelines/paged_index").to route_to("timelines#paged_index")
    end

    xit "routes to #import_variations_timeline" do
      Settings.variations = 'enabled'
      expect(:post => "/timelines/import_variations_timeline").to route_to("timelines#import_variations_timeline")
    end

  end
end
