# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'spec_helper'

describe MasterFilesController do
  describe "#create" do

    before(:each) do
      load_fixture 'avalon:video-segment'
      login_as 'content_provider'
    end

    context "must provide a container id" do
      it "should fail if no container id provided" do
        request.env["HTTP_REFERER"] = "/"
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
             
        lambda { post :create, Filedata: [@file], original: 'any'}.should_not change { MasterFile.count }
      end
    end
     
    context "cannot upload a file over the defined limit" do
     it "should provide a warning about the file size" do
      request.env["HTTP_REFERER"] = "/"
            
      @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
      @file.stub(:size).and_return(MasterFile::MAXIMUM_UPLOAD_SIZE + 2^21)  
     
      lambda { post :create, Filedata: [@file], original: 'any', container_id: 'avalon:video-segment'}.should_not change { MasterFile.count }
     
      flash[:errors].should_not be_nil
     end
    end
     
    context "must be a valid MIME type" do
      it "should recognize a video format" do
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        post :create, 
          Filedata: [@file], 
          original: 'any', 
          container_id: 'avalon:video-segment' 

        mediaobject = MediaObject.find('avalon:video-segment')
        master_file = mediaobject.parts.first
        master_file.file_format.should eq "Moving image" 
             
        flash[:errors].should be_nil
      end
           
     it "should recognize an audio format" do
       @file = fixture_file_upload('/jazz-performance.mp3', 'audio/mp3')
       post :create, 
         Filedata: [@file], 
         original: 'any', 
         container_id: 'avalon:video-segment' 

       mediaobject = MediaObject.find('avalon:video-segment')
       master_file = mediaobject.parts.first
       master_file.file_format.should eq "Sound" 
     end
       
     it "should reject non audio/video format" do
       request.env["HTTP_REFERER"] = "/"
       load_fixture 'avalon:electronic-resource'
     
       @file = fixture_file_upload('/public-domain-book.txt', 'application/json')
        Rubyhorn.stub_chain(:client,:stop).and_return(true)

       lambda { post :create, Filedata: [@file], original: 'any', container_id: 'avalon:electronic-resource' }.should_not change { MasterFile.count }
       logger.debug "<< Flash errors is present? #{flash[:errors]} >>"
     
       flash[:errors].should_not be_nil
     end
    
     it "should recognize audio/video based on extension when MIMETYPE is of unknown format" do
       @file = fixture_file_upload('/videoshort.mp4', 'application/octet-stream')
    
       post :create, 
         Filedata: [@file], 
         original: 'any', 
         container_id: 'avalon:video-segment' 
       master_file = MasterFile.find(:all, order: "created_on ASC").last
       master_file.file_format.should eq "Moving image" 
             
       flash[:errors].should be_nil
     end
    end
     
    context "should process file successfully" do
      it "should associate with a MediaObject" do
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        #Work-around for a Rails bug
        class << @file
          attr_reader :tempfile
        end
   
        post :create, Filedata: [@file], original: 'any', container_id: 'avalon:video-segment'
         
        master_file = MasterFile.find(:all, order: "created_on ASC").last
        mediaobject = MediaObject.find('avalon:video-segment')
        mediaobject.parts.should include master_file
        master_file.mediaobject.pid.should eq('avalon:video-segment')
         
        flash[:errors].should be_nil        
      end
    end

    context "should have default permissions" do
      it "should set edit_user and edit_group" do
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        #Work-around for a Rails bug
        class << @file
          attr_reader :tempfile
        end
   
        post :create, Filedata: [@file], original: 'any', container_id: 'avalon:video-segment'
        master_file = MasterFile.find(:all, order: "created_on ASC").last
        master_file.edit_groups.should include "collection_manager"
        master_file.edit_users.should include "archivist2"
      end
    end
  end
  
  describe "#update" do
    context "should handle Matterhorn pingbacks" do
      it "should create Derivatives when processing succeeded" do
        #stub Rubyhorn call and return a workflow fixture and check that Derivative.create_from_master_file is called
        xml = File.new("spec/fixtures/matterhorn_workflow_doc.xml")
        doc = Rubyhorn::Workflow.from_xml(xml)
        Rubyhorn.stub_chain(:client,:instance_xml).and_return(doc)
        Rubyhorn.stub_chain(:client,:get).and_return(nil)
        Rubyhorn.stub_chain(:client,:stop).and_return(true)
        mf = MasterFile.create!
        mo = MediaObject.new
        mo.save(validate: false)
        mf.mediaobject = mo
        mf.save
        mo.save
        put :update, id: mf.pid, workflow_id: 1103
 
        mf = MasterFile.find(mf.pid)
        logger.debug mf.derivatives.count
        mf.derivatives.count.should eq 3
      end
    end
  end
  
  describe "#destroy" do
    context "should be deleted" do
      it "should no longer exist" do
          login_as 'content_provider'
  
          media_object = MediaObject.new
          media_object.save(validate: false)
          master_file = MasterFile.new
          master_file.save
          master_file.mediaobject = media_object
          master_file.mediaobject.save(validate:false)
          master_file.save
         Rubyhorn.stub_chain(:client,:stop).and_return(true) 

        lambda { post :destroy, id: master_file.pid }.should change { MasterFile.count }.by(-1)
      end
    end
    
    context "should stop processing in Matterhorn" do
      it "should no longer be in the Matterhorn pipeline"
    end
    
    context "should no longer be associated with its parent object" do
      it "should create then remove a file from a video object" do
        login_as 'content_provider'
          
        media_object = MediaObject.new
        media_object.save(validate: false)
        master_file = MasterFile.new
        master_file.save
        master_file.mediaobject = media_object
        master_file.mediaobject.save(validate:false)
        master_file.save
        Rubyhorn.stub_chain(:client,:stop).and_return(true)

        lambda { post :destroy, id: master_file.pid }.should change { MasterFile.count }.by(-1)
        media_object.parts.should_not include master_file         
      end
    end
  end
  
end
