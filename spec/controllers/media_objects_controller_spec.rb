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

describe MediaObjectsController, type: :controller do
  render_views

  describe "#new" do
    it "should redirect to sign in page with a notice when unauthenticated" do
      lambda { get 'new' }.should_not change { MediaObject.count }
      flash[:notice].should_not be_nil
      response.should redirect_to(new_user_session_path)
    end
  
    it "should redirect to home page with a notice when authenticated but unauthorized" do
      login_as('student')
      lambda { get 'new' }.should_not change { MediaObject.count }
      flash[:notice].should_not be_nil
      response.should redirect_to(root_path)
    end

    context "Default permissions should be applied" do
      it "should be editable by the creator" do
        login_as('content_provider')
        lambda { get 'new' }.should change { MediaObject.count }
        pid = MediaObject.find(:all).last.pid
        response.should redirect_to(edit_media_object_path(id: pid))
      end

      it "should inherit default permissions" do
        login_as 'content_provider'
        get 'new'
        assigns(:mediaobject).edit_groups.should eq ["collection_manager"]
        assigns(:mediaobject).edit_users.should eq ['archivist2'] 
      end
    end
  end

  describe "#edit" do
    it "should redirect to sign in page with a notice on when unauthenticated" do    
      load_fixture 'avalon:electronic-resource'

      get 'edit', id: 'avalon:electronic-resource'
      flash[:notice].should_not be_nil

      response.should redirect_to(new_user_session_path)
    end
  
    it "should redirect to show page with a notice when authenticated but unauthorized" do
      load_fixture 'avalon:print-publication'
      login_as('student')
      
      get 'edit', id: 'avalon:print-publication'
      flash[:notice].should_not be_nil
      response.should redirect_to(media_object_path 'avalon:print-publication')
    end

    it "should redirect to first workflow step if authorized to edit" do
       login_as 'content_provider'
       load_fixture "avalon:print-publication"

       get 'edit', id: 'avalon:print-publication'
       response.should be_success
       response.should render_template HYDRANT_STEPS.first.template
     end
    
    it "should not default to the Access Control page" do
      pending "[VOV-1165] Wait for product owner feedback on which step to default to"
    end

    context "Updating the metadata should result in valid input" do
      it "should ignore the PID if provided as a parameter"
      it "should ignore invalid attributes"
      it "should be able to retrieve an existing record from Fedora" do
        load_fixture 'avalon:video-segment'
        mo = MediaObject.find 'avalon:video-segment'
        mo.workflow.last_completed_step = 'resource-description'
         
        # Set the task so that it can get to the resource-description step
        login_as 'content_provider'
        get :edit, {id: 'avalon:video-segment', step: 'resource-description'}
        response.response_code.should == 200
      end
    end
  end

  describe "#show" do
    context "Known items should be retrievable" do
      it "should be accesible by its PID" do
        load_fixture 'avalon:video-segment'
        get :show, id: 'avalon:video-segment'

        response.response_code.should == 200
      end

      it "should return an error if the PID does not exist" do
        get :show, id: 'no-such-object'
        response.response_code.should == 404
      end

      it "should be available to an collection manager when unpublished" do
        load_fixture 'avalon:video-segment'
        mo = MediaObject.find('avalon:video-segment')
        mo.access = "public"
        mo.save
        
        login_as 'content_provider'
        get 'show', id: 'avalon:video-segment'
        response.should_not redirect_to new_user_session_path
      end

      it "should provide a JSON stream description to the client" do
        fixtures = ['avalon:video-segment',
          'avalon:electronic-resource',
          'avalon:print-publication',
          'avalon:musical-performance']
        fixtures.collect { |f| load_fixture f }
        
        mo = MediaObject.find 'avalon:print-publication' 
        mo.access = "public"
        mo.save

        mo.parts.collect { |part| 
          package_id = part.mediapackage_id 
          get 'show', id: 'avalon:print-publication', format: 'json', content: part.pid
          json_obj = JSON.parse(response.body)
          json_obj['mediapackage_id'].should == part.mediapackage_id
        }
      end
    end
    
    context "Items should not be available to unauthorized users" do
      it "should not be available when unpublished" do
        load_fixture 'avalon:electronic-resource'

        mo = MediaObject.find 'avalon:electronic-resource' 
        mo.access = "private"
        mo.save
        
        get 'show', id: 'avalon:electronic-resource'
        response.should redirect_to new_user_session_path
      end
    end
  end
    
  describe "#destroy" do
    before(:each) do 
      login_as 'cataloger'
      load_fixture 'avalon:electronic-resource'
    end
    
    it "should remove the MediaObject from the system" do
      load_fixture 'avalon:electronic-resource'
      delete :destroy, id: 'avalon:electronic-resource'

      MediaObject.exists?('avalon:electronic-resource').should == false
    end

    it "should not be accessible through the search interface" do
      load_fixture 'avalon:electronic-resource'
      delete :destroy, id: 'avalon:electronic-resource'

      pending "Figure out how to make the right query against Solr"
    end

    # This test may need to be more robust to catch errors but is just a first cut
    # for the time being
    it "should not be possible to delete an object which does not exist" do
      pending "Fix access controls to stop throwing exception"
      delete :destroy, id: 'avalon:this-pid-is-fake'
      response.should redirect_to root_path
    end
  end

  describe "#update_status" do
    before(:each) do
      login_as('content_provider')
      @media_object = MediaObject.new(pid: 'avalon:status-update')
      request.env["HTTP_REFERER"] = '/'
    end

    it 'publishes media object' do
      @media_object.save(validate: false)
      get 'update_status', :id => 'avalon:status-update', :status => 'publish'
      MediaObject.find('avalon:status-update').published?.should be_true
    end

    it 'unpublishes media object' do
      @media_object.avalon_publisher = 'archivist'
      @media_object.save(validate: false)
      get 'update_status', :id => 'avalon:status-update', :status => 'unpublish' 
      MediaObject.find('avalon:status-update').published?.should be_false
    end
  end

  describe "#deliver_content" do
    before(:each) do
      load_fixture 'avalon:electronic-resource'
    end

    it 'cannot inspect metadata anonymously' do
      get 'deliver_content', :id => 'avalon:electronic-resource', :datastream => 'descMetadata'
      response.response_code.should == 401
    end

    it 'cannot inspect metadata without authorization' do
      login_as 'student'
      get 'deliver_content', :id => 'avalon:electronic-resource', :datastream => 'descMetadata'
      response.response_code.should == 401
    end

    it 'can inspect metadata with authorization' do
      login_as 'content_provider'
      get 'deliver_content', :id => 'avalon:electronic-resource', :datastream => 'descMetadata'
      response.response_code.should == 200
      response.body.should be_equivalent_to(MediaObject.find('avalon:electronic-resource').descMetadata.content)
    end

    it 'returns a not found error for nonexistent datastreams' do
      login_as 'content_provider'
      get 'deliver_content', :id => 'avalon:electronic-resource', :datastream => 'nonExistentMetadata'
      response.response_code.should == 404
    end
  end
end
