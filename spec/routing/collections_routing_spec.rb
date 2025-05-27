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

require "rails_helper"

RSpec.describe CollectionsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/collections").to route_to("collections#index")
    end

    it "routes to #show" do
      expect(:get => "/collections/1").to route_to("collections#show", id: "1")
    end

    it "routes to #poster" do
      expect(:get => "/collections/1/poster").to route_to("collections#poster", id: "1")
    end

    context 'json requests' do
      it "routes to #index" do
        expect(:get => "/collections.json").to route_to("collections#index", format: 'json')
      end

      it "routes to #show" do
        expect(:get => "/collections/1.json").to route_to("collections#show", id: "1", format: 'json')
      end
    end
  end
end
