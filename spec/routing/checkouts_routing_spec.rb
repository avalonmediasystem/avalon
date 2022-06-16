require "rails_helper"

RSpec.describe CheckoutsController, type: :routing do
  describe "routing" do
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

    it "routes to #display_all" do
      expect(get: "checkouts/display_returned").to route_to("checkouts#display_all")
    end
  end
end
