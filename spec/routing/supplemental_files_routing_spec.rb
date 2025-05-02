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

RSpec.describe MasterFilesController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(:get => "/master_files/abc1234/supplemental_files/edf567").to route_to("supplemental_files#show", master_file_id: 'abc1234', id: 'edf567')
    end
    it "routes to #delete" do
      expect(:delete => "/master_files/abc1234/supplemental_files/edf567").to route_to("supplemental_files#destroy", master_file_id: 'abc1234', id: 'edf567')
    end
    it "routes to #create" do
      expect(:post => "/master_files/abc1234/supplemental_files").to route_to("supplemental_files#create", master_file_id: 'abc1234')
    end
    it "routes to #update" do
      expect(:put => "/master_files/abc1234/supplemental_files/edf567").to route_to("supplemental_files#update", master_file_id: 'abc1234', id: 'edf567')
    end
    it "routes to #captions" do
      expect(:get => "/master_files/abc1234/supplemental_files/edf567/captions").to route_to("supplemental_files#captions", master_file_id: 'abc1234', id: 'edf567')
    end
    # Redirects are not testable from the routing spec out of the box.
    # Forcing the tests to `type: :request` to keep routing tests in one place.
    it "redirects to supplemental_files#show", type: :request do
      get "/master_files/abc1234/supplemental_files/edf567/transcripts"
      expect(response).to redirect_to("/master_files/abc1234/supplemental_files/edf567")
    end
  end
end
