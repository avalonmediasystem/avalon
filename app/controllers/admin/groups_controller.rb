# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

# -*- encoding : utf-8 -*-
require "avalon/role_controls"
class Admin::GroupsController < ApplicationController
  before_action :auth

  # Currently assumes that to do anything you have to be able to manage Group
  def auth
    authorize! :manage, Admin::Group
    if params['id'].present?
      # Replace this with authorize! ?
      g = Admin::Group.find(params['id'])
      if cannot? :manage, g
        flash[:error] = "You must be an administrator to manage the '#{g.name}' group"
        redirect_to admin_groups_path
      end
    end
  end

  def index
    default_groups = Settings.groups.system_groups
    @default_groups = []
    @groups = []

    #TODO: move RoleControls to Group model
    Admin::Group.all.each do |group|
      if default_groups.include? group.name
        @default_groups << group
      else
        @groups << group
      end
    end
  end

  def new
    @group = Admin::Group.new
  end

  def create
    name = params['admin_group'].strip
    if Admin::Group.exists?(name)
      flash[:error] = "Group name #{name} is taken."
      redirect_to admin_groups_path
      return
    end

    @group = Admin::Group.new
    @group.name = name
    if @group.save
      redirect_to edit_admin_group_path(@group)
    else
      flash[ :error ] = @group.errors
      redirect_to admin_groups_path
    end
  end

  def edit
    @group = Admin::Group.find(params[:id])
  end

  def update
    #TODO: move RoleControls to Group model

    new_user = params["new_user"]
    new_group_name = params["group_name"]

    @group = Admin::Group.find(params["id"])

    # Make sure that the group is not part of the list of special system
    # groups. If it is then do not allow the name to be changed and cause
    # other things to break in the system
    #
    # It is not pretty but this gets the job done. Even though the view
    # prevents the name being changed this is a safeguard against somebody
    # posting it anyways
    if params["group_name"].present? and !@group.name.eql?(params["group_name"])
      if Admin::Group.name_is_static?(@group.name)
        flash[:error] = "Cannot change the name of a system group [#{new_group_name}]"
        redirect_to edit_admin_group_path(@group)
        return
      else
        # This logic makes sure that role is never blank even if the form
        # does not provide a value
        if Admin::Group.exists?(params["group_name"])
          flash[:error] = "Group name #{params["group_name"]} is taken."
          redirect_to edit_admin_group_path(@group)
          return
        end
        @group.name = new_group_name.blank? ? params["id"] : params["group_name"]
      end
    end
    @group.users += [new_user.strip] unless new_user.blank?

    if @group.save
      flash[:success] = "Successfully updated group \"#{@group.name}\""
    end
    redirect_to edit_admin_group_path(@group)
  end

  def destroy
    Admin::Group.find(params[:id]).delete
    redirect_to admin_groups_path
  end

  def update_users
    group_name = params[:id]
    sole_managers = check_for_sole_managers if group_name == "manager"
    if !sole_managers.blank?
      flash[:error] = "Cannot remove users #{sole_managers.join(",")} because they are sole managers of collections."
    else
      users = Avalon::RoleControls.users(group_name) - params[:user_ids]
      Avalon::RoleControls.assign_users(users, group_name)
      Avalon::RoleControls.save_changes
    end
    redirect_back(fallback_location: edit_admin_group_path(group_name))
  end

  # Only deletes multiple groups for now
  # TODO: able to add/remove an ability to multple groups
  def update_multiple
    params[:group_ids].each do |group_name|
      Admin::Group.find(group_name).delete
    end

    flash[:notice] = "Successfully deleted groups: #{params[:group_ids].join(", ")}"
    redirect_to admin_groups_path
  end

  def check_for_sole_managers
    sole_managers = []
    params["user_ids"].each do |manager|
      sole_managers << manager if Admin::Collection.all.any? {|c| c.managers == [manager]}
    end
    sole_managers
  end
end
