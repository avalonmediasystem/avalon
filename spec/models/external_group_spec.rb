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

require 'rails_helper'

describe ExternalGroup do
  it "ldap_lookup should return [] if LDAP is not configured" do
    hide_const("Avalon::GROUP_LDAP")
    expect( ExternalGroup.ldap_lookup('foo') ).to eq([])
  end
  it "ldap_lookup should return ['Group1','Group2'] for mock LDAP" do
    stub_const("Avalon::GROUP_LDAP", Net::LDAP.new)
    stub_const("Avalon::GROUP_LDAP_TREE", 'ou=Test,dc=avalonmediasystem,dc=org')
    entry1 = Net::LDAP::Entry.new("dc=ads,dc=example,dc=edu")
    entry1["cn"]="Group1"
    entry2 = Net::LDAP::Entry.new("dc=ads,dc=example,dc=edu")
    entry2["cn"]="Group2"
    allow_any_instance_of(Net::LDAP).to receive(:search).and_return([entry1,entry2])
    expect( ExternalGroup.ldap_lookup('Group') ).to eq( [{id:'Group1',display:'Group1'},{id:'Group2',display:'Group2'}] )
    expect( ExternalGroup.autocomplete('Group') ). to eq( ExternalGroup.ldap_lookup('Group') )
  end
end
