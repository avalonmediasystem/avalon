require 'spec_helper'


describe MediaObjectsController do
  render_views

  describe "creating a new media object" do
    it "should redirect to sign in page with a notice when unauthenticated" do
      lambda { get 'new' }.should_not change { MediaObject.count }
      flash[:notice].should_not be_nil
      response.should redirect_to(new_user_session_path)
    end
  
    it "should redirect to home page with a notice when authenticated but unauthorized" do
      login_as('student')
      lambda { get 'new' }.should_not change { MediaObject.count }
      flash[:notice].should_not be_nil
      response.should redirect_to(root_path)
    end

    context "Default permissions should be applied" do
      it "should be editable by the creator" do
        login_as('content_provider')
        lambda { get 'new' }.should change { MediaObject.count }
        pid = MediaObject.find(:all).last.pid
        response.should redirect_to(edit_media_object_path(id: pid, step: 'file_upload'))
      end

      it "should inherit default permissions" do
        login_as('content_provider')
        get 'new'
        assigns(:mediaobject).edit_groups.should eq ["archivist"]
        assigns(:mediaobject).edit_users.should eq ['archivist2'] #FIXME make this lookup the username from factory girl
      end
    end
  end

  describe "editing a media object" do
    it "should redirect to sign in page with a notice on when unauthenticated" do    
      pid = 'hydrant:318'
      load_fixture pid

      get 'edit', id: pid
      flash[:notice].should_not be_nil

      response.should redirect_to(new_user_session_path)
    end
  
    it "should redirect to show page with a notice when authenticated but unauthorized" do
      pid = 'hydrant:318'
      load_fixture pid
      login_as('student')
      
      get 'edit', id: pid
      flash[:notice].should_not be_nil
      response.should redirect_to(media_object_path pid)
    end

    it "should redirect to first workflow step if authorized to edit" do
      pid = "hydrant:318"
      load_fixture pid
      login_as('cataloger')
      get 'edit', id: pid
      response.should be_success
      response.should render_template('file_upload')
    end

  end

  describe "#show" do
    context "Known items should be retrievable" do
      it "should be accesible by its PID"
      it "should return an error if the PID does not exist"
    end
  end
    
  describe "#destroy" do
    it "should remove the MediaObject from the system"
    it "should not be accessible through the search interface"
  end
end
