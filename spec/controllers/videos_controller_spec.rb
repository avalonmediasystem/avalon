require 'spec_helper'

describe VideosController do
	render_views

  describe "creating a new video" do
  	it "should redirect to sign in page with a notice on unauthenticated new" do
  	  lambda { get 'new' }.should_not change { Video.count }
  	  flash[:notice].should_not be_nil
  	  response.should redirect_to(new_user_session_path)
  	end
	
  	it "should redirect to home page with a notice on authenticated but unauthorized new" do
      login_user
  	  lambda { get 'new' }.should_not change { Video.count }
  	  flash[:notice].should_not be_nil
  	  response.should redirect_to(root_path)
  	end
  end

  describe "editting a video" do
  	it "should redirect to sign in page with a notice on an unauthenticated edit" do    
      pid = 'hydrant:318'
      load_fixture pid

      get 'edit', id: pid
      flash[:notice].should_not be_nil
      response.should redirect_to(new_user_session_path)
  	end
	
  	it "should redirect to show page with a notice on authenticated but unauthorized edit" do
      pid = 'hydrant:318'
      load_fixture pid
      login_user
      
      get 'edit', id: pid
      flash[:notice].should_not be_nil
      response.should redirect_to(video_path pid)
  	end
  end
end