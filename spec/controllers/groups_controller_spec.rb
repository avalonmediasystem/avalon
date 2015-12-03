# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
  	  expect { get 'new' }.not_to change { Admin::Group.all.count }
  	  expect(flash[:notice]).not_to be_nil
  	  expect(response).to redirect_to(new_user_session_path)
  	end
	
    it "should redirect to home page with a notice when authenticated but unauthorized" do
      login_as('student')
      expect { get 'new' }.not_to change {Admin::Group.all.count}
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).not_to be_nil
    end

    it "should redirect to group index page with a notice when group name is already taken" do
      group = FactoryGirl.create(:group)
      login_as('policy_editor')
      expect { post 'create', admin_group: group.name }.not_to change {Admin::Group.all.count }
      expect(flash[:error]).not_to be_nil
      expect(response).to redirect_to(admin_groups_path)
    end

    context "Default permissions should be applied" do
      it "should be create-able by the policy_editor" do
        login_as('policy_editor')
        expect { post 'create', admin_group: test_group }.to change { Admin::Group.all.count }
        g = Admin::Group.find(test_group)
        expect(g).not_to be_nil
        expect(response).to redirect_to(edit_admin_group_path(g))
      end
    end
    
    # Cleans up
    after(:each) do
      clean_groups [test_group, test_group_new]
    end
  end

  describe "Modifying a group: " do
    let!(:group) {Admin::Group.find(FactoryGirl.create(:group).name)}
    
    context "editing a group" do
      it "should redirect to sign in page with a notice on when unauthenticated" do    
        get 'edit', id: group.name
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(new_user_session_path)
      end
    
      it "should redirect to home page with a notice when authenticated but unauthorized" do
        login_as('student')
      
        get 'edit', id: group.name
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(root_path)
      end
    
      it "should be able to change group users when authenticated and authorized" do
        login_as('policy_editor')
        new_user = FactoryGirl.build(:user).username

        put 'update', group_name: group.name, id: group.name, new_user: new_user

        group_name = group.name
        group = Admin::Group.find(group_name)
        expect(group.users).to include(new_user)
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(edit_admin_group_path(Admin::Group.find(group.name)))
      end
    
      it "should be able to change group name when authenticated and authorized" do
        login_as('policy_editor')
        new_group_name = Faker::Lorem.word

        put 'update', group_name: new_group_name, id: group.name
    
        new_group = Admin::Group.find(new_group_name)
        expect(new_group).not_to be_nil
        expect(new_group.users).to eq(group.users)
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(edit_admin_group_path(new_group))
      end
      
      it "should not be able to rename system groups" do
        login_as('administrator')
        put 'update', group_name: Faker::Lorem.word, id: 'manager'
        
        expect(Admin::Group.find('manager')).not_to be_nil
        expect(flash[:error]).not_to be_nil
      end

      it "should be able to remove users from a group" do
        login_as('policy_editor')
        request.env["HTTP_REFERER"] = '/admin/groups/manager/edit'
        
        put 'update_users', id: group.name, user_ids: Admin::Group.find(group.name).users

        expect(Admin::Group.find(group.name).users).to be_empty
        expect(flash[:error]).to be_nil
      end

      it "should not remove users from the manager group if they are sole managers of a collection" do
        login_as('policy_editor')
        request.env["HTTP_REFERER"] = '/admin/groups/manager/edit'

        collection = FactoryGirl.create(:collection)
        manager_name = collection.managers.first
        put 'update_users', id: 'manager', user_ids: [manager_name]

        expect(Admin::Group.find('manager').users).to include(manager_name)
        expect(flash[:error]).not_to be_nil
      end

      ['administrator','group_manager'].each do |g|
        it "should be able to manage #{g} group as an administrator" do
          login_as('administrator')
          new_user = FactoryGirl.build(:user).username

          put 'update', id: g, new_user: new_user
          group = Admin::Group.find(g)
          expect(group.users).to include(new_user)
          expect(flash[:notice]).not_to be_nil
          expect(response).to redirect_to(edit_admin_group_path(Admin::Group.find(group.name)))
        end

        it "should not be able to manage #{g} group as a group_manager" do
          login_as('policy_editor')
          new_user = FactoryGirl.build(:user).username

          put 'update', id: g, new_user: new_user
          group = Admin::Group.find(g)
          expect(group.users).not_to include(new_user)
          expect(flash[:error]).not_to be_nil
          expect(response).to redirect_to(admin_groups_path)
        end
      end
    end
    
    context "Deleting a group" do
      it "should redirect to sign in page with a notice on when unauthenticated" do    
        
        expect { put 'update_multiple', group_ids: [group.name] }.not_to change { RoleControls.users(group.name) }
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(new_user_session_path)
      end
    
      it "should redirect to home page with a notice when authenticated but unauthorized" do
        login_as('student')
      
        expect { put 'update_multiple', group_ids: [group.name] }.not_to change { RoleControls.users(group.name) }
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(root_path)
      end
    
      it "should be able to change group users when authenticated and authorized" do
        login_as('policy_editor')
      
        expect { put 'update_multiple', group_ids: [group.name] }.to change { RoleControls.users(group.name) }
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(admin_groups_path)
      end
    end
  end
end
