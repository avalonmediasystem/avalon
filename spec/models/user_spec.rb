# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
    it {should validate_presence_of(:username)}
    it {should validate_uniqueness_of(:username)}
    it {should validate_presence_of(:email)}
    it {should validate_uniqueness_of(:email)}
  end

  describe "Ability" do
    its(:ability) {should_not be_nil}

    pending "should create a new Ability if missing"
    pending "should delegate can? and cannot?"
  end

  describe "Membership" do
    it "should be a member if its key is in the list" do
      user.should be_in(list,[user.user_key])
      user.should be_in(list+[user.user_key])
    end

    it "should not be a member if its key is not in the list" do
      user.should_not be_in(list)
    end
  end

  describe "#groups" do
    it "should return only virtual groups if there are any" do
      vgroups = ["foo", "bar"]
      user.virtual_groups = vgroups
      RoleMapper.should_not_receive(:roles)
      expect(user.groups).to eq(vgroups)
    end
    it "should return groups from the role map" do
      groups = ["foorole"]
      RoleMapper.should_receive(:roles).and_return(groups)
      expect(user.groups).to eq(groups)
    end
  end

  describe "Virtual groups" do
    its(:virtual_groups) {should_not be_nil}
    its(:virtual_groups) {should be_a Array}
    its(:virtual_groups) {should be_empty}
  end
end
