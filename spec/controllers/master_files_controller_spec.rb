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
     
      load_fixture 'hydrant:video-segment'
            
      @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
      @file.stub(:size).and_return(MasterFile::MAXIMUM_UPLOAD_SIZE + 2^21)  
     
      lambda { post :create, Filedata: [@file], original: 'any', container_id: 'hydrant:video-segment'}.should_not change { MasterFile.count }
      puts "<< Flash message is present? #{flash[:notice]} >>"
     
      flash[:errors].should_not be_nil
     end
    end
     
    context "must be a valid MIME type" do
      it "should recognize a video format" do
        login_as_archivist
     
        load_fixture 'hydrant:video-segment'
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        post :create, 
          Filedata: [@file], 
          original: 'any', 
          container_id: 'hydrant:video-segment' 

	master_file = MediaObject.find('hydrant:video-segment')
        master_file = master_file.parts.first
        master_file.media_type.should eq "Moving image" 
             
        flash[:errors].should be_nil
      end
           
     it "should recognize an audio format" do
       login_as_archivist

       load_fixture 'hydrant:video-segment'
       @file = fixture_file_upload('/jazz-performance.mp3', 'audio/mp3')
       post :create, 
         Filedata: [@file], 
         original: 'any', 
         container_id: 'hydrant:video-segment' 

       master_file = MediaObject.find('hydrant:video-segment')
       master_file = master_file.parts.first
       master_file.media_type.should eq "Sound" 
     end
       
     it "should reject non audio/video format" do
           login_as_archivist
           request.env["HTTP_REFERER"] = "/"
     
           load_fixture 'hydrant:electronic-resource'
     
           @file = fixture_file_upload('/public-domain-book.txt', 'application/json')
     
           lambda { post :create, Filedata: [@file], original: 'any', container_id: 'hydrant:electronic-resource' }.should_not change { MasterFile.count }
           puts "<< Flash errors is present? #{flash[:errors]} >>"
     
           flash[:errors].should_not be_nil
     end
    
     it "should recognize audio/video based on extension when MIMETYPE is of unknown format" do
       login_as_archivist
    
       load_fixture 'hydrant:video-segment'
       @file = fixture_file_upload('/videoshort.mp4', 'application/octet-stream')
    
       post :create, 
         Filedata: [@file], 
         original: 'any', 
         container_id: 'hydrant:video-segment' 
       master_file = MasterFile.find(:all, order: "created_on ASC").last
       master_file.media_type.should eq "Moving image" 
             
       flash[:errors].should be_nil
     end
    end
     
   context "should process file successfully" do
     it "should associate with a MediaObject" do
         login_as_archivist
   
         load_fixture 'hydrant:video-segment'
         @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
         #Work-around for a Rails bug
         class << @file
           attr_reader :tempfile
         end
         
#         controller.stub!(:sendOriginalToMatterhorn).and_return(nil)
   
         post :create, Filedata: [@file], original: 'any', container_id: 'hydrant:video-segment'
         
         master_file = MasterFile.find(:all, order: "created_on ASC").last
         mediaobject = MediaObject.find('hydrant:video-segment')
         mediaobject.parts.should include master_file
         master_file.container.pid.should eq('hydrant:video-segment')
         
         flash[:errors].should be_nil        
     end
          
    end
  end
    
  describe "#update" do
  end
  
  describe "#destroy" do
    context "should be deleted" do
      it "should no longer exist" do
          login_as_archivist
  
          media_object = MediaObject.new
          media_object.save(validate: false)
          master_file = MasterFile.new
          master_file.save
          master_file.container = media_object
          master_file.container.save(validate:false)
          master_file.save
  
        lambda { post :destroy, id: master_file.pid }.should change { MasterFile.count }
      end
    end
    
    context "should stop processing in Matterhorn" do
      it "should no longer be in the Matterhorn pipeline"
    end
    
    context "should no longer be associated with its parent object" do
      it "should create then remove a file from a video object" do
        login_as_archivist
          
        media_object = MediaObject.new
        media_object.save(validate: false)
        master_file = MasterFile.new
        master_file.save
        master_file.container = media_object
        master_file.container.save(validate:false)
        master_file.save
          
        lambda { post :destroy, id: master_file.pid }.should change { MasterFile.count }
        media_object.parts.should_not include master_file         
      end
    end
  end
  
end
