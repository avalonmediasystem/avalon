# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

describe ObjectsController do
  describe "#show" do
    it "should redirect you to root if no object is found" do
      get :show, params: { id: 'avalon:bad-pid' }
      expect(response).to redirect_to root_path
    end

    it "should redirect you to the object show page" do
      obj = FactoryBot.create(:media_object)
      get :show, params: { id: obj.id }
      expect(response).to redirect_to(media_object_path(obj))
    end

    it "should pass along request params" do
      obj = FactoryBot.create(:media_object)
      get :show, params: { id: obj.id, foo: 'bar' }
      expect(response).to redirect_to(media_object_path(obj, {foo: 'bar'}))
    end

    it "should redirect to appended url" do
      obj = FactoryBot.create(:master_file)
      get :show, params: { id: obj.id, urlappend: 'embed' }
      expect(response).to redirect_to(master_file_path(obj)+"/embed")
    end

    it "works for global ids" do
      obj = FactoryBot.create(:playlist)
      get :show, params: { id: obj.to_gid_param }
      expect(response).to redirect_to(playlist_path(obj))
    end

    it "does not append urlappend if invalid" do
      obj = FactoryBot.create(:media_object)
      get :show, params: { id: obj.id, urlappend: 'http://google.com' }
      expect(response).to redirect_to(media_object_path(obj))
    end
  end

  describe "#autocomplete" do
    it "should call autocomplete on the specified model" do
      user = FactoryBot.create(:user, email: "test@example.com")
      get :autocomplete, params: { t: 'user', q: 'test' }
      expect(response.body).to include user.user_key
    end
  end
end
