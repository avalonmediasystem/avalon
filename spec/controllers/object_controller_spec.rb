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
      FactoryGirl.create(:user, email: "test@example.com")
      get :autocomplete, t: 'user', q: 'test'
      expect(response.body).to include "test@example.com" 
    end
  end
end
