require 'spec_helper'

describe MasterFilesController do
  describe "#create" do
	  context "must provide a container id" do
      it "should fail if no container id provided" do
        login_as_archivist
        request.env["HTTP_REFERER"] = "/"
          
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        
        lambda { post :create, Filedata: [@file], original: 'any'}.should_not change { MasterFile.count }
      end
	  end

    context "cannot upload a file over the defined limit" do
      it "should provide a warning about the file size" do
       login_as_archivist
       request.env["HTTP_REFERER"] = "/"

       pid = 'hydrant:318'
       load_fixture pid
       
       @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
       @file.stub(:size).and_return(MasterFilesController::MAXIMUM_UPLOAD_SIZE + 2^21)  

       lambda { post :create, Filedata: [@file], original: 'any', container_id: pid }.should_not change { MasterFile.count }
       puts "<< Flash message is present? #{flash[:notice]} >>"

       flash[:errors].should_not be_nil
      end
    end
	  
	  context "must be a valid MIME type" do
	    it "should recognize a video format" do
        login_as_archivist

        pid = 'hydrant:short-form-video'
        load_fixture pid
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')

        controller.stub!(:saveOriginalToHydrant).and_return(MasterFile.new)
        controller.stub!(:sendOriginalToMatterhorn).and_return(nil)

        lambda { post :create, Filedata: [@file], original: 'any', container_id: pid }.should change { MasterFile.count }.by(1)
        puts MasterFile.find(:all, order: "created_on ASC").last.inspect
        MasterFile.find(:all, order: "created_on ASC").last.media_type.should eq(["video"])
        
        flash[:errors].should be_nil
      end
      
	    it "should recognize an audio format" 
	    
	    it "should recognize an unknown format" do
        login_as_archivist
        request.env["HTTP_REFERER"] = "/"

        pid = 'hydrant:318'
        load_fixture pid

        @file = fixture_file_upload('/public-domain-book.txt', 'application/json')

        lambda { post :create, Filedata: [@file], original: 'any', container_id: pid }.should_not change { MasterFile.count }
        puts "<< Flash errors is present? #{flash[:errors]} >>"

        flash[:errors].should_not be_nil
	    end
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
