require 'spec_helper'


describe VideosController do
  render_views

  describe "creating a new video" do
  	it "should redirect to sign in page with a notice when unauthenticated" do
  	  lambda { get 'new' }.should_not change { Video.count }
  	  flash[:notice].should_not be_nil
  	  response.should redirect_to(new_user_session_path)
  	end
	
  	it "should redirect to home page with a notice when authenticated but unauthorized" do
      login_as('student')
  	  lambda { get 'new' }.should_not change { Video.count }
  	  flash[:notice].should_not be_nil
  	  response.should redirect_to(root_path)
  	end

	  context "Default permissions should be applied" do
      it "should be editable by the creator" do
	login_as('content_provider')
  	  lambda { get 'new' }.should change { Video.count }
#	  response.should redirect_to(video_path)
       end
      it "should inherit default permissions" do
        login_as('content_provider')
	get 'new'
	assigns(:video).edit_groups.should eq ["archivist"]
	assigns(:video).edit_users.should eq ['archivist2'] #FIXME make this lookup the username from factory girl
      end
    end
  end

  describe "editting a video" do
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
      response.should redirect_to(video_path pid)
  	end
  end

  describe "#show" do
    context "Known items should be retrievable" do
      it "should be accesible by its PID"
      it "should return an error if the PID does not exist"
    end
  end
    
  describe "#destroy" do
    it "should remove the Video from the system"
    it "should not be accessible through the search interface"
  end
end
