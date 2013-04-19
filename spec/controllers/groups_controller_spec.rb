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


describe Admin::GroupsController do
  render_views
  test_group = "rspec_test_group"
  test_group_new = "rspec_test_group_new"

  describe "creating a new group" do
  	it "should redirect to sign in page with a notice when unauthenticated" do
  	  lambda { get 'new' }.should_not change { Admin::Group.all.count }
  	  flash[:notice].should_not be_nil
  	  response.should redirect_to(new_user_session_path)
  	end
	
    it "should redirect to home page with a notice when authenticated but unauthorized" do
      login_as('student')
      lambda { get 'new' }.should_not change {Admin::Group.all.count }
      flash[:notice].should_not be_nil
      response.should redirect_to(root_path)
    end

    context "Default permissions should be applied" do
      it "should be create-able by the policy_editor" do
        login_as('policy_editor')
        lambda { post 'create', admin_group: test_group }.should change { Admin::Group.all.count }
        g = Admin::Group.find(test_group)
        g.should_not be_nil
        response.should redirect_to(edit_admin_group_path(g))
      end
    end
    
    # Cleans up
    after(:each) do
      clean_groups [test_group, test_group_new]
    end
  end

  describe "Modifying a group: " do
    before(:each) do
      clean_groups [test_group, test_group_new]
      
      g = Admin::Group.new
      g.name = test_group       
      g.save
    end 
    
    after(:each) do
      clean_groups [test_group, test_group_new]
    end 
    
    context "editing a group" do
      it "should redirect to sign in page with a notice on when unauthenticated" do    
        get 'edit', id: test_group
        flash[:notice].should_not be_nil
        response.should redirect_to(new_user_session_path)
      end
    
      it "should redirect to home page with a notice when authenticated but unauthorized" do
        login_as('student')
      
        get 'edit', id: test_group
        flash[:notice].should_not be_nil
        response.should redirect_to(root_path)
      end
    
      it "should be able to change group users when authenticated and authorized" do
        login_as('policy_editor')

        lambda { put 'update', :id => test_group, group_name: test_group, new_user: "test_change_user"}.should change { Admin::Group.find(test_group).users }
        flash[:notice].should_not be_nil
        response.should redirect_to(edit_admin_group_path Admin::Group.find(test_group))
      end
    
      it "should be able to change group name when authenticated and authorized" do
        login_as('policy_editor')
      
        post 'update', group_name: test_group_new, new_user: "", id: test_group
      
        Admin::Group.find(test_group).should be_nil
        Admin::Group.find(test_group_new).should_not be_nil
        flash[:notice].should_not be_nil

        response.should redirect_to(edit_admin_group_path Admin::Group.find(test_group_new))
      end
    end
    
    context "Deleting a group" do
      it "should redirect to sign in page with a notice on when unauthenticated" do    
        
        lambda { put 'update_multiple', group_ids: [test_group] }.should_not change { RoleControls.users(test_group) }
        flash[:notice].should_not be_nil
        response.should redirect_to(new_user_session_path)
      end
    
      it "should redirect to home page with a notice when authenticated but unauthorized" do
        login_as('student')
      
        lambda { put 'update_multiple', group_ids: [test_group] }.should_not change { RoleControls.users(test_group) }
        flash[:notice].should_not be_nil
        response.should redirect_to(root_path)
      end
    
      it "should be able to change group users when authenticated and authorized" do
        login_as('policy_editor')
      
        lambda { put 'update_multiple', group_ids: [test_group] }.should change { RoleControls.users(test_group) }
        flash[:notice].should_not be_nil
        response.should redirect_to(admin_groups_path)
      end
    end
  end
end
