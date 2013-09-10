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
    let!(:collection) { FactoryGirl.create(:collection) }
    before(:each) do
      request.env["HTTP_REFERER"] = '/'
    end

    it "should redirect to sign in page with a notice when unauthenticated" do
      lambda { get 'new', collection_id: collection.pid }.should_not change { MediaObject.count }
      flash[:notice].should_not be_nil
      response.should redirect_to(new_user_session_path)
    end
  
    it "should redirect to home page with a notice when authenticated but unauthorized" do
      login_as :user
      lambda { get 'new', collection_id: collection.pid }.should_not change { MediaObject.count }
      flash[:notice].should_not be_nil
      response.should redirect_to(root_path)
    end

    it "should not let manager of other collections create an item in this collection" do
      pending
    end

    context "Default permissions should be applied" do
      it "should be editable by the creator" do
        login_user collection.managers.first
        lambda { get 'new', collection_id: collection.pid }.should change { MediaObject.count }
        pid = MediaObject.find(:all).last.pid
        response.should redirect_to(edit_media_object_path(id: pid))
      end

      it "should copy default permissions from its owning collection" do
        login_user collection.depositors.first

        get 'new', collection_id: collection.pid 
         
        #MediaObject.all.last.edit_users.should include(collection.managers)
        #MediaObject.all.last.edit_users.should include(collection.depositors)
      end
    end

  end

  describe "#edit" do
    let!(:media_object) { FactoryGirl.create(:media_object) }

    it "should redirect to sign in page with a notice when unauthenticated" do   
      get 'edit', id: media_object.pid
      flash[:notice].should_not be_nil
      response.should redirect_to(new_user_session_path)
    end
  
    it "should redirect to show page with a notice when authenticated but unauthorized" do
      login_as :user
      
      get 'edit', id: media_object.pid
      flash[:notice].should_not be_nil
      response.should redirect_to(media_object_path(media_object.pid) )
    end

    it "should redirect to first workflow step if authorized to edit" do
       login_user media_object.collection.managers.first

       get 'edit', id: media_object.pid
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
        media_object.workflow.last_completed_step = 'resource-description'
        media_object.save
         
        # Set the task so that it can get to the resource-description step
        login_user media_object.collection.managers.first
        get :edit, {id: media_object.pid, step: 'resource-description'}
        response.response_code.should == 200
      end
    end
  end

  describe "#show" do
    let!(:media_object) { FactoryGirl.create(:published_media_object, access: 'public') }

    context "Known items should be retrievable" do
      it "should be accesible by its PID" do
        get :show, id: media_object.pid
        response.response_code.should == 200
      end

      it "should return an error if the PID does not exist" do
        get :show, id: 'no-such-object'
        response.response_code.should == 404
      end

      it "should be available to a manager when unpublished" do
        login_user media_object.collection.managers.first
        get 'show', id: media_object.pid
        response.should_not redirect_to new_user_session_path
      end

      it "should provide a JSON stream description to the client" do
        master_file = FactoryGirl.create(:master_file)
        master_file.mediaobject = media_object
        master_file.save

        mopid = media_object.pid
        media_object = MediaObject.find(mopid)

        media_object.parts.collect { |part| 
          package_id = part.mediapackage_id 
          get 'show', id: media_object.pid, format: 'json', content: part.pid
          json_obj = JSON.parse(response.body)
          json_obj['mediapackage_id'].should == part.mediapackage_id
        }
      end
    end

    describe 'Redirect back to media object after sign in' do
      let(:media_object){ FactoryGirl.create(:media_object, access: 'private') }

      context 'Before sign in' do
        it 'persists the current url on the session' do
          get 'show', id: media_object.pid
          session[:previous_url].should eql media_object_path(media_object)
        end
      end

      context 'After sign in' do
        before do 
          @user = FactoryGirl.create(:user)
          @media_object = FactoryGirl.create(:media_object, access: 'private', read_users: [@user.username] )
        end
        it 'redirects to the previous url' do
        end
        it 'removes the previous url from the session' do
        end
      end
    end
    
    context "Items should not be available to unauthorized users" do
      it "should redirect to sign in when not logged in and item is unpublished" do
        media_object.publish!(nil)
        media_object.should_not be_published
        get 'show', id: media_object.pid
        response.should redirect_to new_user_session_path
      end

      it "should redirect to home page when logged in and item is unpublished" do
        media_object.publish!(nil)
        media_object.should_not be_published
        login_as :user
        get 'show', id: media_object.pid
        response.should redirect_to root_path
      end
    end
  end
    
  describe "#destroy" do
    let!(:media_object) { FactoryGirl.create(:media_object) }
    before(:each) do 
      login_user media_object.collection.managers.first
    end
    
    it "should remove the MediaObject from the system" do
      delete :destroy, id: media_object.pid
      MediaObject.exists?(media_object.pid).should == false
    end

    it "should not be accessible through the search interface" do
      delete :destroy, id: media_object.pid
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
    let!(:media_object) { FactoryGirl.create(:media_object) }
    before(:each) do
      login_user media_object.collection.managers.first
      request.env["HTTP_REFERER"] = '/'
    end

    it 'publishes media object' do
      get 'update_status', :id => media_object.pid, :status => 'publish'
      MediaObject.find(media_object.pid).published?.should be_true
    end

    it 'unpublishes media object' do
      media_object.avalon_publisher = media_object.collection.managers.first
      media_object.save
      get 'update_status', :id => media_object.pid, :status => 'unpublish' 
      MediaObject.find(media_object.pid).published?.should be_false
    end
  end

  describe "#remove_part" do
    
    before(:each) do 
      @stub_media_object = FactoryGirl.create(:media_object)
      @stub_master_file = FactoryGirl.create(:master_file)
      @stub_media_object.parts = [@stub_master_file]
      @stub_media_object.save!
    end
    
    it "should remove a section if it exists" do
      request.env["HTTP_REFERER"] = media_object_path(id: @stub_media_object)
      put 'remove_part', id: @stub_media_object, section: @stub_master_file

      expect { @stub_media_object.parts.empty? }.to be_true
      expect { @stub_master_file.nil? }.to be_true
      expect { flash[:error].nil? }.to be_true
    end
  
    it "should throw an error if the Media Object does not exist"  do
      request.env["HTTP_REFERER"] = media_object_path(id: @stub_media_object)
      put 'remove_part', id: 'avalon:bad_pid', section: @stub_master_file

      expect { flash[:error].nil? }.to be_false
    end

    it "should throw an error if the part exists but does not belong to that Media Object" do
      request.env["HTTP_REFERER"] = media_object_path(id: @stub_media_object)
      new_master_file = FactoryGirl.create(:master_file)
      put 'remove_part', id: @stub_media_object, section: new_master_file

      expect { flash[:error].nil? }.to be_false
    end

    it "should throw an error if the part does not exist" do
      request.env["HTTP_REFERER"] = media_object_path(id: @stub_media_object)
      put 'remove_part', id: @stub_media_object, section: 'avalon:bad_pid'

      expect { flash[:error].nil? }.to be_false
    end

    # Test that the delete button only appears with the right permissions and that a
    # general user cannot hit the method with an HTTP request
    it "should not allow somebody without permission to delete a part" do
      request.env["HTTP_REFERER"] = media_object_path(id: @stub_media_object)
      put 'remove_part', id: @stub_media_object, section: @stub_master_file

      expect { flash[:error].nil? }.to be_false
    end

    it "should not affect the order of the rest of the parts" do
      parts = 2.upto(rand(5)).collect { FactoryGirl.create(:master_file) }
      parts << @stub_master_file 
      @stub_media_object.parts = parts.shuffle
      @stub_media_object.save!
      part_order = @stub_media_object.parts - [@stub_master_file]
      request.env["HTTP_REFERER"] = media_object_path(id: @stub_media_object)
      put 'remove_part', id: @stub_media_object, section: @stub_master_file

      expect { @stub_media_object.parts == part_order }.to be_true
    end
  end
end
