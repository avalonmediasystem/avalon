# -*- encoding : utf-8 -*-
require "role_controls"
class Admin::GroupsController < ApplicationController  
  before_filter :auth
  
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
    @groups = []
    RoleControls.roles.each do |r|
      group = Admin::Group.new
      group.name = r
      group.users = RoleControls.users(r)
      group.save
      
      @groups << group
    end
    
    render layout: 'admin'
  end
  
  def new
    @group = Admin::Group.new
    puts "PERSISTED?" unless @group.persisted?
    render layout: "admin"
  end
  
  def create
    role = params["admin_group"]["name"]
    users = params["admin_group"]["users"]

    if !role.empty?
      RoleControls.add_role(role)
      RoleControls.assign_users(users, role)
      RoleControls.save_changes
    end
    
    redirect_to admin_groups_path
  end
  
  def edit
    @group = Admin::Group.new
    @group.name = params[:id]
    @group.users = RoleControls.users(@group.name)
    @group.save
    RoleControls.save_changes
    
    render layout: "admin"
  end
  
  def update
    group_name = params["id"]
    new_group_name = params["admin_group"]["name"]
    
    if group_name != new_group_name
      RoleControls.remove_role group_name
      RoleControls.add_role new_group_name
    end
    
    RoleControls.assign_users(params["admin_group"]["users"], new_group_name)
    RoleControls.save_changes
    
    flash[:notice] = "Successfully updated group \"#{new_group_name}\""
    redirect_to admin_groups_path
  end

  # Only deletes multiple groups for now
  # TODO: able to add/remove an ability to multple groups
  def update_multiple
    params[:group_ids].each do |group|
      RoleControls.remove_role(group)
    end
    RoleControls.save_changes
    
    flash[:notice] = "Successfully deleted groups: #{params[:group_ids].join(", ")}"
    redirect_to admin_groups_path
  end
end 
