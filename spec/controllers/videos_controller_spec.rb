require 'spec_helper'

describe VideosController do
  describe "#create" do
    context "Public users should not be able to create new assets" do
	  it "should redirect to sign in page with a notice on unauthenticated new" do
	    lambda { get 'new' }.should_not change { Video.count }
	    flash[:notice].should_not be_nil
	    response.should redirect_to(new_user_session_path)
	  end
	end
	
	context "Logged in users without permission should not be able to create new items" do
	  it "should redirect to home page with a notice on authenticated but unauthorized new" do
      login_user
	    lambda { get 'new' }.should_not change { Video.count }
	    flash[:notice].should_not be_nil
	    response.should redirect_to(root_path)
	  end
	end
  end
  
  describe "#update" do
	context "Public users should not be able to edit an item" do
	  it "should redirect to sign in page with a notice on unauthenticated edit"
      # lambda { get 'new' }.should_not change { Video.count }
      # flash[:notice].should_not be_nil
      # response.should redirect_to(new_user_session_path)
	end
	
	context "Users with limited permissions should not be able to edit items" do
	  it "should redirect to home page with a notice on authenticated but unauthorized edit" 
    # lambda { get 'new' }.should_not change { Video.count }
    # flash[:notice].should_not be_nil
    # response.should redirect_to(root_path)
	end	
  end
end