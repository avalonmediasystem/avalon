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

describe User do
  subject {user}
  let!(:user) {FactoryGirl.build(:user)}
  let!(:list) {0.upto(rand(5)).collect { Faker::Internet.email }}

  describe "validations" do
    it {is_expected.to validate_presence_of(:username)}
    it {is_expected.to validate_uniqueness_of(:username)}
    it {is_expected.to validate_presence_of(:email)}
    it {is_expected.to validate_uniqueness_of(:email)}
  end

  describe "Membership" do
    it "should be a member if its key is in the list" do
      expect(user).to be_in(list,[user.user_key])
      expect(user).to be_in(list+[user.user_key])
    end

    it "should not be a member if its key is not in the list" do
      expect(user).not_to be_in(list)
    end
  end

  describe "#groups" do
    let(:groups)  { ["foorole"] }
    it "should return groups from the role map" do
      expect(RoleMapper).to receive(:roles).and_return(groups)
      expect(user.groups).to eq(groups)
    end
  end

  describe "#ldap_groups" do
    it "should return [] if LDAP is not configured" do
      hide_const("Avalon::GROUP_LDAP")
      expect(user.send(:ldap_groups)).to eq([])
    end
    it "user should belong to Group1 and Group2 in mock LDAP" do
      entry = Net::LDAP::Entry.new("cn=user,dc=ads,dc=example,dc=edu")
      entry["memberof"] = ['CN=Group1,DC=ads,DC=example,DC=edu"','CN=Group2,DC=ads,DC=example,DC=edu"']
      allow_any_instance_of(Net::LDAP).to receive(:search).and_return([entry])
      expect(user.send(:ldap_groups)).to eq(['Group1','Group2'])
    end
  end

  describe "#autocomplete" do
    it "should return results of same type as user_key (email xor username)" do
      user.save(validate: false)
      expect(User.autocomplete(user.user_key)).to eq([{id: user.user_key, display: user.user_key}])
    end
  end

  describe "#destroy" do
    it 'removes bookmarks for user' do
      media_object = FactoryGirl.create(:published_media_object)
      user = FactoryGirl.create(:public)
      bookmark = Bookmark.create(document_id: media_object.pid, user_id: user.id) 
      expect { user.destroy }.to change { Bookmark.exists? bookmark }.from( true ).to( false )
    end
  end

end
