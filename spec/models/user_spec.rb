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
  describe "Ability" do
    subject {user}
    let!(:user) {FactoryGirl.build(:user)}
    let!(:media_object) {FactoryGirl.create(:media_object)}

    its(:ability) {should_not be_nil}

    it "should not be able to read unauthorized, published MediaObject" do
      media_object.access = 'private'
      media_object.avalon_publisher = ["random"]
      media_object.save
      user.can?(:read, media_object).should be_false
    end

    it "should not be able to read authorized, unpublished MediaObject" do
      media_object.read_users = [user.user_key]
      media_object.should_not be_published
      user.can?(:read, media_object).should be_false
    end

    it "should be able to read authorized, published MediaObject" do
      media_object.read_users += [user.user_key]
      media_object.avalon_publisher = ["random"]
      media_object.save
      user.can?(:read, media_object).should be_true
    end
  end
end
