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
    let(:groups)  { ["foorole"] }
    it "should return groups from the role map" do
      RoleMapper.should_receive(:roles).and_return(groups)
      expect(user.groups).to eq(groups)
    end
  end

end
