# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'spec_helper'

describe "Routes" do
  describe "Collections" do
    it {expect(:get=> "/admin/collections").to route_to(controller: 'admin/collections', action: 'index')}
    it {expect(:get=> "/admin/collections/new").to route_to(controller: 'admin/collections', action: 'new')}
    it {expect(:get=> "/admin/collections/1").to route_to(controller: 'admin/collections', action: 'show', id: '1')}
    it {expect(:get=> "/admin/collections/1/edit").to route_to(controller: 'admin/collections', action: 'edit', id: '1')}
    it {expect(:post=> "/admin/collections").to route_to(controller: 'admin/collections', action: 'create')}
    it {expect(:put=> "/admin/collections/1").to route_to(controller: 'admin/collections', action: 'update', id:'1')}
    it {expect(:delete=> "/admin/collections/1").to route_to(controller: 'admin/collections', action: 'destroy', id:'1')}
  end
end
