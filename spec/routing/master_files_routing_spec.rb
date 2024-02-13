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

RSpec.describe MasterFilesController, type: :routing do
  describe "routing" do
    it "routes to #move" do
      expect(:post => "/master_files/abc1234/move").to route_to("master_files#move", id: 'abc1234')
    end
    it "routes to #caption_manifest" do
      expect(:get => "/master_files/abc1234/caption_manifest/def5678").to route_to("master_files#caption_manifest", id: 'abc1234', c_id: 'def5678')
    end
  end
end
