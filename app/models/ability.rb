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

class Ability
  include CanCan::Ability
  include Hydra::Ability
  include Hydra::PolicyAwareAbility

  def create_permissions(user=nil, session=nil)
    if @user_groups.include? "administrator"
      can :manage, MediaObject
      can :manage, MasterFile
      can :inspect, MediaObject
      can :manage, Dropbox
      can :manage, Admin::Group
      can :manage, Admin::Collection
    end
    
    if @user_groups.include? "group_manager"
      can :manage, Admin::Group
    end

    if is_member_of_any_collection?
      can :create, MediaObject
    end

    if @user_groups.include? "manager"
      can :create, Admin::Collection
    end
  end

  def custom_permissions(user=nil, session=nil)
    unless @user_groups.include? "administrator"
      cannot :read, MediaObject do |mediaobject|
        !mediaobject.published? && !test_edit(mediaobject.pid)
      end

      can :read, Admin::Collection do |collection|
        is_member_of?(collection)
      end

      unless (is_member_of_any_collection? or @user_groups.include? 'manager')
        cannot :read, Admin::Collection
      end
    
      can :read, MasterFile do |master_file|
        can? :read, masterfile.mediaobject
      end

      can :read, Derivative do |derivative|
        can? :read, derivative.masterfile.mediaobject
      end

      cannot :update, MediaObject do |mediaobject|
        (!is_member_of?(mediaobject.collection)) || 
          ( mediaobject.published? && !@user.in?(mediaobject.collection.managers) )
      end

      cannot :destroy, MediaObject do |mediaobject|
        # non-managers can only destroy mediaobject if it's unpublished 
        (!is_member_of?(mediaobject.collection)) || 
          ( mediaobject.published? && !@user.in?(mediaobject.collection.managers) )
      end

      can :update_access_control, MediaObject do |mediaobject|
        @user.in?(mediaobject.collection.managers) || 
          (is_editor_of?(mediaobject.collection) && !mediaobject.published?)
      end

      can :unpublish, MediaObject do |mediaobject|
        @user.in?(mediaobject.collection.managers) 
      end

      cannot :destroy, Admin::Collection do |collection, other_user_collections=[]|
        !@user.in?(collection.managers)
      end

      can :update, Admin::Collection do |collection|
        is_editor_of?(collection) 
      end

      can :update_unit, Admin::Collection do |collection|
        @user.in?(collection.managers)
      end

      can :update_access_control, Admin::Collection do |collection|
        @user.in?(collection.managers)
      end

      can :update_managers, Admin::Collection do |collection|
        @user.in?(collection.managers)
      end

      can :update_editors, Admin::Collection do |collection|
        @user.in?(collection.managers)
      end

      can :update_depositors, Admin::Collection do |collection|
        is_editor_of?(collection) 
      end
      
      can :inspect, MediaObject do |mediaobject| 
       is_member_of?(mediaobject.collection) 
      end 
    end
  end

  def is_member_of?(collection)
     @user_groups.include?("administrator") || 
       @user.in?(collection.managers, collection.editors, collection.depositors)
  end

  def is_editor_of?(collection) 
     @user_groups.include?("administrator") || 
       @user.in?(collection.managers, collection.editors)
  end

  def is_member_of_any_collection?
    @user.id.present? and Admin::Collection.where("#{ActiveFedora::SolrService.solr_name("inheritable_edit_access_person", Hydra::Datastream::RightsMetadata.indexer)}" => @user.user_key).first.present?
  end
end
