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
    before (:each) do
      @user = User.new
      @user.username = "test"
      @mo = MediaObject.new
      @mo.save(:validate=>false)
    end

    it "should have an ability" do
      @user.ability.should_not be_nil
    end

    it "should not be able to read any MediaObject" do
      assert @user.cannot?(:read, @mo)
    end

    it "should not be able to read authorized, unpublished MediaObject" do
      @mo.read_users = [@user.user_key]
      assert @user.cannot?(:read, @mo)
    end

    it "should be able to read authorized, published MediaObject" do
      @mo.read_users += [@user.user_key]
      @mo.avalon_publisher = ["random"]
      @mo.save(:validate=>false)
      assert @user.can?(:read, @mo)
    end
  end
end
