require 'spec_helper'

describe MasterFilesController do
  #   describe "#create" do
  #     context "must provide a container id" do
  #           it "should fail if no container id provided" do
  #             login_as_archivist
  #             request.env["HTTP_REFERER"] = "/"
  #               
  #             @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
  #             
  #             lambda { post :create, Filedata: [@file], original: 'any'}.should_not change { MasterFile.count }
  #           end
  #     end
  #     
  #         context "cannot upload a file over the defined limit" do
  #           it "should provide a warning about the file size" do
  #            login_as_archivist
  #            request.env["HTTP_REFERER"] = "/"
  #     
  #            pid = 'hydrant:318'
  #            load_fixture pid
  #            
  #            @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
  #            @file.stub(:size).and_return(MasterFilesController::MAXIMUM_UPLOAD_SIZE + 2^21)  
  #     
  #            lambda { post :create, Filedata: [@file], original: 'any', container_id: pid }.should_not change { MasterFile.count }
  #            puts "<< Flash message is present? #{flash[:notice]} >>"
  #     
  #            flash[:errors].should_not be_nil
  #           end
  #         end
  #     
  #     context "must be a valid MIME type" do
  #       it "should recognize a video format" do
  #             login_as_archivist
  #     
  #             pid = 'hydrant:short-form-video'
  #             load_fixture pid
  #             @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
  #     
  #             controller.stub!(:saveOriginalToHydrant).and_return(MasterFile.new)
  #             controller.stub!(:sendOriginalToMatterhorn).and_return(nil)
  #     
  #             lambda { post :create, Filedata: [@file], original: 'any', container_id: pid }.should change { MasterFile.count }.by(1)
  #             MasterFile.find(:all, order: "created_on ASC").last.media_type.should eq(["video"])
  #             
  #             flash[:errors].should be_nil
  #           end
  #           
  #       it "should recognize an audio format" 
  #       
  #       it "should reject non audio/video format" do
  #             login_as_archivist
  #             request.env["HTTP_REFERER"] = "/"
  #     
  #             pid = 'hydrant:318'
  #             load_fixture pid
  #     
  #             @file = fixture_file_upload('/public-domain-book.txt', 'application/json')
  #     
  #             lambda { post :create, Filedata: [@file], original: 'any', container_id: pid }.should_not change { MasterFile.count }
  #             puts "<< Flash errors is present? #{flash[:errors]} >>"
  #     
  #             flash[:errors].should_not be_nil
  #       end
  # 
  #       it "should recognize audio/video based on extension when MIMETYPE is of unknown format" do
  #         login_as_archivist
  # 
  #         pid = 'hydrant:short-form-video'
  #         load_fixture pid
  #         @file = fixture_file_upload('/videoshort.mp4', 'application/octet-stream')
  # 
  #         controller.stub!(:saveOriginalToHydrant).and_return(MasterFile.new)
  #         controller.stub!(:sendOriginalToMatterhorn).and_return(nil)
  # 
  #         lambda { post :create, Filedata: [@file], original: 'any', container_id: pid }.should change { MasterFile.count }.by(1)
  #         MasterFile.find(:all, order: "created_on ASC").last.media_type.should eq(["video"])
  #         
  #         flash[:errors].should be_nil
  #       end
  #     end
  #     
  #   context "should process file successfully" do
  #     it "should save a copy in Hydrant" do
  #         login_as_archivist
  # 
  #         pid = 'hydrant:short-form-video'
  #         load_fixture pid
  #         @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
  #         # Work-around for a Rails bug
  #         class << @file
  #           attr_reader :tempfile
  #         end
  #         
  #         controller.stub!(:sendOriginalToMatterhorn).and_return(nil)
  # 
  #         post :create, Filedata: [@file], original: 'any', container_id: pid
  #         
  #         master_file = MasterFile.find(:all, order: "created_on ASC").last
  #         path =  File.join(Rails.public_path, master_file.url.first)
  #         File.should exist path
  #         
  #         flash[:errors].should be_nil        
  #     end
  #     
  #     it "should send a copy to Matterhorn and get the workflow id back" do
  #         login_as_archivist
  # 
  #         pid = 'hydrant:short-form-video'
  #         load_fixture pid
  #         @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
  #         # Work-around for a Rails bug
  #         class << @file
  #           attr_reader :tempfile
  #         end
  #         
  #         post :create, Filedata: [@file], original: 'any', container_id: pid
  #         
  #         master_file = MasterFile.find(:all, order: "created_on ASC").last
  #         master_file.source.should_not be_empty
  #         puts master_file.source
  #         
  #         flash[:errors].should be_nil        
  #     end
  #   end
  # end
	
	describe "#update" do
	end
	
	describe "#destroy" do
	  context "should be deleted" do
	    it "should be no longer exist" do
        login_as_archivist
        pid = 'hydrant:short-form-video'
        load_fixture pid
        
        master_file = MasterFile.new
        master_file.save
        master_file.container = MediaObject.find(pid)
        master_file.container.save
        master_file.save
        
	      lambda { post :destroy, id: master_file.pid }.should change { MasterFile.count }
	    end
	  end
	  
	  context "should stop processing in Matterhorn" do
	    it "should no longer be in the Matterhorn pipeline"
	  end
	  
	  context "should no longer be associated with its parent object" do
	    pending "Create then remove a file from a video object"
	  end
	end
	
	describe 
end
