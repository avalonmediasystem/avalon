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

require "rails_helper"

RSpec.describe CheckoutsController, type: :routing do
  describe "routing" do
    context "controlled digital lending is enabled" do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
      it "routes to #index" do
        expect(get: "/checkouts").to route_to("checkouts#index")
      end

      it "routes to #create" do
        expect(post: "/checkouts").to route_to("checkouts#create")
      end

      it "routes to #show via GET" do
        expect(get: "/checkouts/1").to route_to("checkouts#show", id: "1")
      end

      it "routes to #update via PUT" do
        expect(put: "/checkouts/1").to route_to("checkouts#update", id: "1")
      end

      it "routes to #update via PATCH" do
        expect(patch: "/checkouts/1").to route_to("checkouts#update", id: "1")
      end

      it "routes to #destroy" do
        expect(delete: "/checkouts/1").to route_to("checkouts#destroy", id: "1")
      end

      it "routes to #return_all" do
        expect(patch: "/checkouts/return_all").to route_to("checkouts#return_all")
      end

      it "routes to #return" do
        expect(patch: "/checkouts/1/return").to route_to("checkouts#return", id: "1")
      end
    end
    context "controlled digital lending is disabled" do
      before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false) }
      it "does not route to #index" do
        expect(get: "/checkouts").not_to route_to("checkouts#index")
      end

      it "does not route to #create" do
        expect(post: "/checkouts").not_to route_to("checkouts#create")
      end

      it "does not route to #show via GET" do
        expect(get: "/checkouts/1").not_to route_to("checkouts#show", id: "1")
      end

      it "does not route to #update via PUT" do
        expect(put: "/checkouts/1").not_to route_to("checkouts#update", id: "1")
      end

      it "does not route to #update via PATCH" do
        expect(patch: "/checkouts/1").not_to route_to("checkouts#update", id: "1")
      end

      it "does not route to #destroy" do
        expect(delete: "/checkouts/1").not_to route_to("checkouts#destroy", id: "1")
      end

      it "does not route to #return_all" do
        expect(patch: "/checkouts/return_all").not_to route_to("checkouts#return_all")
      end

      it "does not route to #return" do
        expect(patch: "/checkouts/1/return").not_to route_to("checkouts#return", id: "1")
      end
    end
  end
end
