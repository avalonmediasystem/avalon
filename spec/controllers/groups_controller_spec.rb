# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

require 'rails_helper'


describe Admin::GroupsController do
  render_views
  test_group = "rspec_test_group"
  test_group_new = "rspec_test_group_new"

  describe 'index' do
    it "index should redirect to restricted content page when unauthenticated" do
      get 'index'
      expect(response).to render_template('errors/restricted_pid')
    end

    it "index new should redirect to restricted content page when authenticated but unauthorized" do
      login_as('student')
      get 'index'
      expect(response).to render_template('errors/restricted_pid')
    end
  end

  describe "creating a new group" do
    it "new should redirect to restricted content page when unauthenticated" do
  	  expect { get 'new' }.not_to change { Admin::Group.all.count }
  	  expect(response).to render_template('errors/restricted_pid')
  	end

    it "new should redirect to restricted content page when authenticated but unauthorized" do
      login_as('student')
      expect { get 'new' }.not_to change {Admin::Group.all.count}
      expect(response).to render_template('errors/restricted_pid')
    end

    it "create should redirect to restricted content page when unauthenticated" do
      expect { post 'create', params: { admin_group: test_group } }.not_to change {Admin::Group.all.count }
      expect(response).to render_template('errors/restricted_pid')
    end

    it "create should redirect to restricted content page when authenticated but unauthorized" do
      login_as('student')

      expect { post 'create', params: { admin_group: test_group } }.not_to change {Admin::Group.all.count }
      expect(response).to render_template('errors/restricted_pid')
    end

    it "create should redirect to group index page with a notice when group name is already taken" do
      group = FactoryBot.create(:group)
      login_as('group_manager')
      expect { post 'create', params: { admin_group: group.name } }.not_to change {Admin::Group.all.count }
      expect(response).to redirect_to(admin_groups_path)
      expect(flash[:error]).not_to be_nil
    end

    context "Default permissions should be applied" do
      it "should be create-able by the group_manager" do
        login_as('group_manager')
        expect { post 'create', params: { admin_group: test_group } }.to change { Admin::Group.all.count }
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
    let!(:group) {Admin::Group.find(FactoryBot.create(:group).name)}

    context "editing a group" do
      it "edit should redirect to restricted content page when unauthenticated" do
        get 'edit', params: { id: group.name }
        expect(response).to render_template('errors/restricted_pid')
      end

      it "edit should redirect to restricted content page when authenticated but unauthorized" do
        login_as('student')

        get 'edit', params: { id: group.name }
        expect(response).to render_template('errors/restricted_pid')
      end

      it "update should redirect to restricted content page when unauthenticated" do
        new_user = FactoryBot.build(:user).user_key
        put 'update', params: { group_name: group.name, id: group.name, new_user: new_user }
        expect(response).to render_template('errors/restricted_pid')
      end

      it "update should redirect to restricted content page when authenticated but unauthorized" do
        login_as('student')
        new_user = FactoryBot.build(:user).user_key

        put 'update', params: { group_name: group.name, id: group.name, new_user: new_user }
        expect(response).to render_template('errors/restricted_pid')
      end

      it "should be able to change group users when authenticated and authorized" do
        login_as('group_manager')
        new_user = FactoryBot.build(:user).user_key

        put 'update', params: { group_name: group.name, id: group.name, new_user: new_user }

        group_name = group.name
        group = Admin::Group.find(group_name)
        expect(group.users).to include(new_user)
        expect(flash[:success]).not_to be_nil
        expect(response).to redirect_to(edit_admin_group_path(Admin::Group.find(group.name)))
      end

      it "should be able to change group name when authenticated and authorized" do
        login_as('group_manager')
        new_group_name = Faker::Lorem.word

        put 'update', params: { group_name: new_group_name, id: group.name }

        new_group = Admin::Group.find(new_group_name)
        expect(new_group).not_to be_nil
        expect(new_group.users).to eq(group.users)
        expect(flash[:success]).not_to be_nil
        expect(response).to redirect_to(edit_admin_group_path(new_group))
      end

      it "should not be able to rename system groups" do
        login_as('administrator')
        put 'update', params: { group_name: Faker::Lorem.word, id: 'manager' }

        expect(Admin::Group.find('manager')).not_to be_nil
        expect(flash[:error]).not_to be_nil
      end

      it "should be able to remove users from a group" do
        login_as('group_manager')
        request.env["HTTP_REFERER"] = '/admin/groups/manager/edit'

        put 'update_users', params: { id: group.name, user_ids: Admin::Group.find(group.name).users }

        expect(Admin::Group.find(group.name).users).to be_empty
        expect(flash[:error]).to be_nil
      end

      it "should not remove users from the manager group if they are sole managers of a collection" do
        login_as('group_manager')
        request.env["HTTP_REFERER"] = '/admin/groups/manager/edit'

        collection = FactoryBot.create(:collection)
        manager_name = collection.managers.first
        put 'update_users', params: { id: 'manager', user_ids: [manager_name] }

        expect(Admin::Group.find('manager').users).to include(manager_name)
        expect(flash[:error]).not_to be_nil
      end

      ['administrator','group_manager'].each do |g|
        it "should be able to manage #{g} group as an administrator" do
          login_as('administrator')
          new_user = FactoryBot.build(:user).user_key

          put 'update', params: { id: g, new_user: new_user }
          group = Admin::Group.find(g)
          expect(group.users).to include(new_user)
          expect(flash[:success]).not_to be_nil
          expect(response).to redirect_to(edit_admin_group_path(Admin::Group.find(group.name)))
        end

        it "should not be able to manage #{g} group as a group_manager" do
          login_as('group_manager')
          new_user = FactoryBot.build(:user).user_key

          put 'update', params: { id: g, new_user: new_user }
          group = Admin::Group.find(g)
          expect(group.users).not_to include(new_user)
          expect(flash[:error]).not_to be_nil
          expect(response).to redirect_to(admin_groups_path)
        end
      end
    end

    context "Deleting a group" do
      it "should redirect to restricted content page when unauthenticated" do

        expect { put 'update_multiple', params: { group_ids: [group.name] } }.not_to change { Avalon::RoleControls.users(group.name) }
        expect(response).to render_template('errors/restricted_pid')
      end

      it "should redirect to restricted content page when authenticated but unauthorized" do
        login_as('student')

        expect { put 'update_multiple', params: { group_ids: [group.name] } }.not_to change { Avalon::RoleControls.users(group.name) }
        expect(response).to render_template('errors/restricted_pid')
      end

      it "should be able to change group users when authenticated and authorized" do
        login_as('group_manager')

        expect { put 'update_multiple', params: { group_ids: [group.name] } }.to change { Avalon::RoleControls.users(group.name) }
        expect(flash[:notice]).not_to be_nil
        expect(response).to redirect_to(admin_groups_path)
      end
    end
  end
end
