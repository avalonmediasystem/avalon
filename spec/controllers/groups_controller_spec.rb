require 'spec_helper'


describe Admin::GroupsController do
  render_views
  test_group = "rspec_test_group"
  test_group_new = "rspec_test_group_new"

  describe "creating a new group" do
  	it "should redirect to sign in page with a notice when unauthenticated" do
  	  lambda { get 'new' }.should_not change { RoleControls.roles.count }
  	  flash[:notice].should_not be_nil
  	  response.should redirect_to(new_user_session_path)
  	end
	
    it "should redirect to home page with a notice when authenticated but unauthorized" do
      login_as('student')
      lambda { get 'new' }.should_not change { RoleControls.roles.count }
      flash[:notice].should_not be_nil
      response.should redirect_to(root_path)
    end

    context "Default permissions should be applied" do
      it "should be create-able by the policy_editor" do
        login_as('policy_editor')
        lambda { post 'create', admin_group: { name: test_group, users: [] } }.should change { RoleControls.roles.count }
        response.should redirect_to(admin_groups_path)
        
        # Cleans up
        RoleControls.remove_role test_group
        RoleControls.save_changes
      end
    end
  end

  describe "Modifying a group: " do
    before(:each) do
      clean_groups [test_group, test_group_new]
           
      RoleControls.add_role test_group
    end 
    
    after(:each) do
      clean_groups [test_group, test_group_new]
    end 
    
    context "editting a group" do
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
      
        lambda { post 'update', admin_group: { name: test_group, users: ["test_change_user"], resources: [] }, id: test_group }.should change { RoleControls.users(test_group) }
        flash[:notice].should_not be_nil
        response.should redirect_to(admin_groups_path)
      end
    
      it "should be able to change group name when authenticated and authorized" do
        login_as('policy_editor')
      
        post 'update', admin_group: { name: test_group_new, users: [], resources: [] }, id: test_group
      
        RoleControls.users(test_group).should be_nil
        RoleControls.users(test_group_new).should_not be_nil
        flash[:notice].should_not be_nil
        response.should redirect_to(admin_groups_path)
      end

      # it "should be able to add resources to group when authenticated and authorized" do
      #   login_as('policy_editor')
      #   pid = 'hydrant:318'
      #   load_fixture pid        
      #   
      #   group = Admin::Group.new
      #   group.name = test_group
      #   
      #   lambda { 
      #     post 'update', admin_group: { name: test_group, users: [], resources: [pid] }, id: test_group
      #     puts Video.find(pid).read_groups.inspect
      #   }.should change { group.resources }
      # 
      #   flash[:notice].should_not be_nil
      #   response.should redirect_to(admin_groups_path)
      # end
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
