require 'spec_helper'

describe VideoAssetsController, "creating a new video asset" do
	render_views

	it "should redirect to home page with a notice on large file size" do
	  login_archivist

    @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
    @file.stub(:size).and_return(VideoAssetsController::MAXIMUM_UPLOAD_SIZE + 1)  
	  
    request.env["HTTP_REFERER"] = '/'
    lambda { post :create, Filedata: [@file], original: 'any'}.should_not change { VideoAsset.count }
    flash[:errors].should_not be_nil
    response.should redirect_to('/')
	end
	
end