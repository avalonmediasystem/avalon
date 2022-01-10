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

RSpec.describe Admin::CollectionsController, type: :routing do
  describe "routing" do
    it 'routes to #attach_poster' do
      expect(:post => "/admin/collections/1/poster").to route_to("admin/collections#attach_poster", :id => "1")
    end
    it 'routes to #remove_poster' do
      expect(:delete => "/admin/collections/1/poster").to route_to("admin/collections#remove_poster", :id => "1")
    end
    it 'routes to #poster' do
      expect(:get => "/admin/collections/1/poster").to route_to("admin/collections#poster", :id => "1")
    end
  end
end
