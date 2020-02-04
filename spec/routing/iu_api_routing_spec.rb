require "rails_helper"

RSpec.describe IuApiController, type: :routing do
  describe "routing" do
    it "routes to #media_object_structure" do
      expect(:get => "/iu_api/media_object_structure?id=1").to route_to("iu_api#media_object_structure", id: "1")
      expect(:put => "/iu_api/media_object_structure?id=1").to route_to("iu_api#media_object_structure_update", id: "1")
    end
  end
end