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

describe ObjectController do
  describe "#show" do
    it "should redirect you to root if no object is found" do
      get :show, id: 'avalon:bad-pid'
      response.should redirect_to root_path
    end

    it "should redirect you to the object show page" do
      obj = FactoryGirl.create(:media_object)
      get :show, id: obj.pid
      response.should redirect_to(media_object_path(obj)) 
    end

    it "should pass along request params" do
      obj = FactoryGirl.create(:media_object)
      get :show, id: obj.pid, foo: 'bar'
      response.should redirect_to(media_object_path(obj, {foo: 'bar'}))
    end
    
    it "should redirect to appended url" do
      obj = FactoryGirl.create(:media_object)
      get :show, id: obj.pid, urlappend: 'test'
      response.should redirect_to(media_object_path(obj)+"/test")
    end
  end

  describe "#autocomplete" do
    it "should call autocomplete on the specified model" do
      user = FactoryGirl.create(:user, email: "test@example.com")
      get :autocomplete, t: 'user', q: 'test'
      expect(response.body).to include user.user_key 
    end
  end
end
