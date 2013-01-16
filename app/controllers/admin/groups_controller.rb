# -*- encoding : utf-8 -*-
require "role_controls"
class Admin::GroupsController < ApplicationController  
  before_filter :auth
  layout "admin"
  
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
    
  end
  
  def new
    @group = Admin::Group.new
  end
  
  def create
    @group = Admin::Group.new
    role = params["admin_group"]["name"]
    users = params["admin_group"]["users"]
    
    @group.name = role
    @group.save
    
    logger.debug @group.errors.inspect 
    
    if !role.empty?
      if RoleControls.role_exists? role
        flash[:error] = "Role already exists"
        render :new and return
      end
        
      RoleControls.add_role(role)
      RoleControls.assign_users(users, role)
      RoleControls.save_changes
    else
      flash[:error] = "Role name cannot be empty"
      render :new and return
      return
    end
    
    params["admin_group"]["resources"].each do |resource|
      if !resource.empty?
        resource_obj = Video.find(resource)
        read_groups = resource_obj.read_groups
        read_groups << new_group_name
        resource_obj.read_groups = read_groups
        resource_obj.save
      end
    end
    
    redirect_to admin_groups_path
  end
  
  def edit
    @group = Admin::Group.new
    @group.name = params[:id]
    @group.users = RoleControls.users(@group.name)
    @group.save
    RoleControls.save_changes
  end
  
  def update
    group_name = params["id"]
    new_group_name = params["admin_group"]["name"]
    group = Admin::Group.find(group_name)
    
    # If group name has been changed
    if group_name != new_group_name
      # Changes group name inside each resource's read_groups
      group.resources.each do |resource|
        resource_obj = MediaObject.find(resource)
        read_groups = resource_obj.read_groups
        read_groups.delete(group_name) 
        read_groups << new_group_name
        resource_obj.read_groups = read_groups
        resource_obj.save
      end
      
      RoleControls.remove_role group_name
      RoleControls.add_role new_group_name
    end

    RoleControls.assign_users(params["admin_group"]["users"], new_group_name)
    RoleControls.save_changes
    
    group = Admin::Group.find(new_group_name)
    new_resources = params["admin_group"]["resources"].reject { |r| r.empty? }
    rm_resources = group.resources.reject { |r| new_resources.include? r }

    logger.debug rm_resources.inspect

    # Removes old group from resources that are no longer present in the params
    rm_resources.each do |resource|
        resource_obj = MediaObject.find(resource)
        read_groups = resource_obj.read_groups
        read_groups.delete(new_group_name) 
        resource_obj.read_groups = read_groups
        resource_obj.save
    end    
    
    # Add new groupname to resources 
    new_resources.each do |resource|
        resource_obj = MediaObject.find(resource)
        read_groups = resource_obj.read_groups

        if !read_groups.include? new_group_name
          read_groups << new_group_name 
          resource_obj.read_groups = read_groups
          resource_obj.save
          logger.debug resource_obj.read_groups.inspect
        end
    end    
    
    flash[:notice] = "Successfully updated group \"#{new_group_name}\""
    redirect_to admin_groups_path
  end

  # Only deletes multiple groups for now
  # TODO: able to add/remove an ability to multple groups
  def update_multiple
    params[:group_ids].each do |group_name|
      group = Admin::Group.new
      group.name = group_name      
      group.resources.each do |resource|
        resource_obj = MediaObject.find(resource)
        read_groups = resource_obj.read_groups
        read_groups.delete(group_name) 
        resource_obj.read_groups = read_groups
        resource_obj.save
      end
      
      RoleControls.remove_role(group_name)
    end
    RoleControls.save_changes
    
    flash[:notice] = "Successfully deleted groups: #{params[:group_ids].join(", ")}"
    redirect_to admin_groups_path
  end
end 
