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

# -*- encoding : utf-8 -*-
require "role_controls"
class Admin::GroupsController < ApplicationController  
  before_filter :auth
  layout "avalon"
  
  # Currently assumes that to do anything you have to be able to manage Group
  # TODO: finer controls
  def auth
    if current_user.nil? 
      flash[:notice] = "You need to login to manage groups"
      redirect_to new_user_session_path
    elsif cannot? :manage, Admin::Group
      flash[:notice] = "You do not have permission to manage groups"
      redirect_to root_path
    end
  end
  
  def index
    default_groups = ["collection_manager", "group_manager"]
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
    @group = Admin::Group.new
    @group.name = params["admin_group"]
    if @group.save
      redirect_to edit_admin_group_path(@group)
    else
      redirect_to admin_groups_path
    end 
  end
  
  def edit
    @group = Admin::Group.find(params[:id])
  end
  
  def update
    #TODO: move RoleControls to Group model
    new_group_name = params["group_name"]
    new_user = params["new_user"]

    @group = Admin::Group.find(params["id"])
    @group.name = new_group_name unless new_group_name.blank?
    @group.users += [new_user] unless new_user.blank?
    
    if @group.save
      flash[:notice] = "Successfully updated group \"#{@group.name}\""
    end
    redirect_to edit_admin_group_path(@group) 
  end

  def destroy 
    Admin::Group.find(params[:id]).delete
    redirect_to admin_groups_path 
  end

  def update_users 
    group_name = params[:id]
    users = RoleControls.users(group_name) - params[:user_ids] 
    RoleControls.assign_users(users, group_name)
    RoleControls.save_changes
    redirect_to :back
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
end 
