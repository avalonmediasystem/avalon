# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
require 'rubyhorn/rest_client/exceptions'

describe MasterFilesController do
  describe "#create" do
    let!(:media_object) {FactoryGirl.create(:media_object)}
    let!(:content_provider) {login_user media_object.collection.managers.first}

    context "must provide a container id" do
      it "should fail if no container id provided" do
        request.env["HTTP_REFERER"] = "/"
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
             
        expect { post :create, Filedata: [@file], original: 'any'}.not_to change { MasterFile.count }
      end
    end
     
    context "cannot upload a file over the defined limit" do
     it "should provide a warning about the file size" do
      request.env["HTTP_REFERER"] = "/"
            
      @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
      @file.stub(:size).and_return(MasterFile::MAXIMUM_UPLOAD_SIZE + 2^21)  
     
      expect { post :create, Filedata: [@file], original: 'any', container_id: media_object.pid}.not_to change { MasterFile.count }
     
      flash[:error].should_not be_nil
     end
    end
     
    context "must be a valid MIME type" do
      it "should recognize a video format" do
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        post :create, 
          Filedata: [@file], 
          original: 'any', 
          container_id: media_object.pid 

        master_file = media_object.reload.parts.first
        master_file.file_format.should eq "Moving image" 
             
        flash[:errors].should be_nil
      end
           
     it "should recognize an audio format" do
       @file = fixture_file_upload('/jazz-performance.mp3', 'audio/mp3')
       post :create, 
         Filedata: [@file], 
         original: 'any', 
         container_id: media_object.pid 

       master_file = media_object.reload.parts.first
       master_file.file_format.should eq "Sound" 
     end
       
     it "should reject non audio/video format" do
       request.env["HTTP_REFERER"] = "/"
     
       @file = fixture_file_upload('/public-domain-book.txt', 'application/json')
        Rubyhorn.stub_chain(:client,:stop).and_return(true)

       expect { post :create, Filedata: [@file], original: 'any', container_id: media_object.pid }.not_to change { MasterFile.count }
     
       flash[:error].should_not be_nil
     end
    
     it "should recognize audio/video based on extension when MIMETYPE is of unknown format" do
       @file = fixture_file_upload('/videoshort.mp4', 'application/octet-stream')
    
       post :create, 
         Filedata: [@file], 
         original: 'any', 
         container_id: media_object.pid 
       master_file = MasterFile.all.last
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
   
        post :create, Filedata: [@file], original: 'any', container_id: media_object.pid
         
        master_file = MasterFile.all.last
        media_object.reload.parts.should include master_file
        master_file.mediaobject.pid.should eq(media_object.pid)
         
        flash[:errors].should be_nil        
      end
      it "should associate a dropbox file" do
        skip
        Avalon::Dropbox.any_instance.stub(:find).and_return "spec/fixtures/videoshort.mp4"
        post :create, dropbox: [{id: 1}], original: 'any', container_id: media_object.pid

        master_file = MasterFile.all.last
        media_object.reload
        media_object.parts.should include master_file
        master_file.mediaobject.pid.should eq(media_object.pid)

        flash[:errors].should be_nil
      end
    end
  end
  
  describe "#update" do
    let!(:master_file) {FactoryGirl.create(:master_file)}
    before do
        #stub Rubyhorn call and return a workflow fixture and check that Derivative.create_from_master_file is called
        xml = File.new("spec/fixtures/matterhorn_workflow_doc.xml")
        doc = Rubyhorn::Workflow.from_xml(xml)
        Rubyhorn.stub_chain(:client,:instance_xml).and_return(doc)
        Rubyhorn.stub_chain(:client,:get).and_return(nil)
        Rubyhorn.stub_chain(:client,:stop).and_return(true)
        #Thumbnail and poster datastreams must have some content for saving to succeed
        master_file.thumbnail.mimeType = 'image/png'
        master_file.thumbnail.content = 'PNG'
        master_file.poster.mimeType = 'image/png'
        master_file.poster.content = 'PNG'
        master_file.save 
    end

    context "should handle Matterhorn pingbacks" do
      it "should create Derivatives when processing succeeded" do
        put :update, id: master_file.pid, workflow_id: 1103
        master_file.reload
        master_file.derivatives.count.should == 3
      end
      it "should send success email" do
        allow(IngestBatch).to receive(:all) {[IngestBatch.new(media_object_ids: [master_file.mediaobject.id], name: "Batch #1", email: "test@test.com" )]}
        mailer = double('mailer').as_null_object
        IngestBatchMailer.should_receive(:status_email).and_return(mailer)
        mailer.should_receive(:deliver)
        put :update, id: master_file.pid, workflow_id: 1103
      end
      it "should handle stopped workflows" do
        Rubyhorn.stub_chain(:client, :instance_xml).and_raise Rubyhorn::RestClient::Exceptions::HTTPNotFound
        allow(IngestBatch).to receive(:all) {[IngestBatch.new(media_object_ids: [master_file.mediaobject.id], name: "Batch #1", email: "test@test.com" )]}
        mailer = double('mailer').as_null_object
        IngestBatchMailer.should_receive(:status_email).and_return(mailer)
        mailer.should_receive(:deliver)
        put :update, id: master_file.pid, workflow_id: 1103
      end
    end
  end
  
  describe "#destroy" do
    let!(:master_file) {FactoryGirl.create(:master_file)}

    before(:each) do
      login_user master_file.mediaobject.collection.managers.first
      Rubyhorn.stub_chain(:client,:stop).and_return(true) 
    end

    context "should be deleted" do
      it "should no longer exist" do
        expect { post :destroy, id: master_file.pid }.to change { MasterFile.count }.by(-1)
      end
    end
    
    context "should no longer be associated with its parent object" do
      it "should create then remove a file from a video object" do
        expect { post :destroy, id: master_file.pid }.to change { MasterFile.count }.by(-1)
        master_file.mediaobject.reload.parts.should_not include master_file         
      end
    end
  end

  describe "#show" do
    let!(:master_file) {FactoryGirl.create(:master_file)}
    it "should redirect you to the media object page with the correct section" do
      get :show, id: master_file.pid 
      response.should redirect_to(pid_section_media_object_path(master_file.mediaobject.pid, master_file.pid)) 
    end
  end

  describe "#embed" do
    subject(:mf){FactoryGirl.create(:master_file)}
    it "should render embed layout" do
      login_user mf.mediaobject.collection.managers.first
      expect(get :embed, id: mf.pid ).to render_template(layout: 'embed')
    end
  end

  describe "#set_frame" do
    subject(:mf){FactoryGirl.create(:master_file_with_thumbnail)}
    it "should redirect to sign in when not logged in" do
      expect(get :set_frame, id: mf.pid ).to redirect_to new_user_session_path
    end
    it "should redirect to home when logged in and not authorized" do
      login_as :user
      expect(get :set_frame, id: mf.pid ).to redirect_to root_path
    end
    it "should redirect to edit_media_object" do
      mo = mf.mediaobject
      login_user mo.collection.managers.first
      expect(get :set_frame, id: mf.pid, type: 'thumbnail', offset: '10').to redirect_to edit_media_object_path(mo.pid, step: 'file-upload')
    end
    it "should return thumbnail" do
      expect_any_instance_of(MasterFile).to receive(:extract_still) {'fake image content'}
      login_user mf.mediaobject.collection.managers.first
      get :set_frame, format: 'jpeg', id: mf.pid, type: 'thumbnail', offset: '10'
      expect(response.body).to eq('fake image content')
      expect(response.headers['Content-Type']).to eq('image/jpeg')
    end
  end

  describe "#get_frame" do
    subject(:mf){FactoryGirl.create(:master_file_with_thumbnail)}
    context "not authorized" do
      it "should redirect to sign in when not logged in" do
        expect(get :get_frame, id: mf.pid ).to redirect_to new_user_session_path
      end
      it "should redirect to home when logged in and not authorized" do
        login_as :user
        expect(get :get_frame, id: mf.pid ).to redirect_to root_path
      end
    end
    context "authorized" do
      before(:each) { login_user mf.mediaobject.collection.managers.first }
      it "should return thumbnail" do
        get :get_frame, id: mf.pid, type: 'thumbnail', size: 'bar'
        expect(response.body).to eq('fake image content')
        expect(response.headers['Content-Type']).to eq('image/jpeg')
      end
      it "should return offset thumbnail" do
        expect_any_instance_of(MasterFile).to receive(:extract_still) {'fake image content'}
        get :get_frame, id: mf.pid, type: 'thumbnail', size: 'bar', offset: '1'
        expect(response.body).to eq('fake image content')
        expect(response.headers['Content-Type']).to eq('image/jpeg')
      end
    end
  end
  
end
