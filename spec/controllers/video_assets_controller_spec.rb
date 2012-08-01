require 'spec_helper'

describe VideoAssetsController do
    describe "#create" do
	  context "must provide a file" do
	  end

      context "cannot upload a file over the defined limit" do
	    it "should provide a warning about the file size" do
	     login_as_archivist

         request.env["HTTP_REFERER"] = "/"
         @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
         @file.stub(:size).and_return(VideoAssetsController::MAXIMUM_UPLOAD_SIZE + 2^21)  
	  
         lambda { 
           post :create, Filedata: [@file], original: 'any'}.should_not change { VideoAsset.count }
        puts "<< Flash message is present? #{flash[:notice]} >>"

         flash[:errors].should_not be_nil
	    end
	  end
	  
	  context "must be a valid MIME type" do
	    it "should recognize a video format"	    
	    it "should recognize an audo format" 
	    it "should recognize an unknown format" 
	  end
	  
	  context "should set the appropriate format value" do
	    it "should set a video to 'Moving Image'"
	    it "should set an audio clip to 'Sound'"
	    it "should default to 'Unknown'"
	  end
	end
	
	describe "#update" do
	end
	
	describe "#destroy" do
	  context "should stop processing in Matterhorn" do
	    it "should no longer be in the Matterhorn pipeline"
	  end
	  
	  context "should no longer be associated with its parent object" do
	    pending "Create then remove a file from a video object"
	  end
	end
	
	describe 
end
