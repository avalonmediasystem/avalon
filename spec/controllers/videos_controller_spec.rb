require 'spec_helper'

describe VideosController, "creating a new video" do
	render_views

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
	
	it "should redirect to sign in page with a notice on unauthenticated edit" do
    # lambda { get 'new' }.should_not change { Video.count }
    # flash[:notice].should_not be_nil
    # response.should redirect_to(new_user_session_path)
	end
	
	it "should redirect to home page with a notice on authenticated but unauthorized edit" do
    # lambda { get 'new' }.should_not change { Video.count }
    # flash[:notice].should_not be_nil
    # response.should redirect_to(root_path)
	end
	
end