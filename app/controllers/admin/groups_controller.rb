# -*- encoding : utf-8 -*-
require "role_controls"
class Admin::GroupsController < ApplicationController  
  before_filter :auth
  layout "hydrant"
  
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
    default_groups = ["archivist", "admin_policy_object_editor"]
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
    group_name = params["admin_group"]
    
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
    new_group_name = params["admin_group"]["group_name"]
    puts new_group_name
    new_user = params["new_user"]

    group = Admin::Group.find(params["id"])
    group.name = new_group_name unless new_group_name.blank?
    group.users << new_user unless new_user.blank?
    
    if group.save
      flash[:notice] = "Successfully updated group \"#{new_group_name}\""
    end
    redirect_to edit_admin_group_path(Admin::Group.find(new_group_name)) 
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
