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

require 'rails_helper'

describe RoleMap do
  describe "role map persistor" do
    before :each do
      RoleMap.reset!
    end

    after :each do
      RoleMap.all.each(&:destroy)
    end

    let(:expected_role_map) { { "administrator" => ["archivist1@example.com"], "group_manager" => ["archivist1@example.com"], "manager" => ["archivist1@example.com"], "unit_administrator" => ["archivist1@example.com"] } }

    it "should properly initialize the map" do
      expect(RoleMapper.map).to eq expected_role_map
    end

    it "should properly persist a hash" do
      new_hash = { 'archivist' => ['alice.archivist@example.edu'], 'registered' => ['bob.user@example.edu', 'charlie.user@example.edu'] }
      RoleMap.replace_with!(new_hash)
      expect(RoleMapper.map).to eq(new_hash)
      expect(RoleMap.load).to eq(new_hash)
    end
  end

  describe '#set_entries' do
    let!(:role) { RoleMap.create!(entry: 'group') }

    it 'should not create entries for nils' do
      expect { role.set_entries([nil]) }.not_to change { RoleMap.count }
    end
  end
end
