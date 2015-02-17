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

describe RoleMap do
  describe "role map persistor" do
    before :each do
      RoleMap.reset!
    end

    after :each do
      RoleMap.all.each &:destroy
    end

    it "should properly initialize the map" do
      RoleMapper.map.should == YAML.load(File.read(File.join(Rails.root, "config/role_map_#{Rails.env}.yml")))
    end

    it "should properly persist a hash" do
      new_hash = { 'archivist' => ['alice.archivist@example.edu'], 'registered' => ['bob.user@example.edu','charlie.user@example.edu'] }
      RoleMap.replace_with!(new_hash)
      RoleMapper.map.should == new_hash
      RoleMap.load.should == new_hash
    end
  end
end
