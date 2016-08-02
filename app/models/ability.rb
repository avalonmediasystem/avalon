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

class Ability
  include CanCan::Ability
  include Hydra::Ability
  include Hydra::MultiplePolicyAwareAbility

  def user_groups
    return @user_groups if @user_groups

    @user_groups = default_user_groups
    @user_groups |= current_user.groups if current_user and current_user.respond_to? :groups
    @user_groups |= ['registered'] unless current_user.new_record?
    @user_groups |= @session[:virtual_groups] if @session.present? and @session.has_key? :virtual_groups
    @user_groups |= [@session[:remote_ip]] if @session.present? and @session.has_key? :remote_ip
    @user_groups
  end

  def create_permissions(user=nil, session=nil)
    if full_login?
      if @user_groups.include? "administrator"
        can :manage, MediaObject
        can :manage, MasterFile
        can :inspect, MediaObject
        can :manage, Admin::Group
        can :manage, Admin::Collection
      end

      if @user_groups.include? "group_manager"
        can :manage, Admin::Group do |group|
          group.nil? or !['administrator','group_manager'].include?(group.name)
        end
      end

      if is_member_of_any_collection?
        can :create, MediaObject
      end

      if @user_groups.include? "manager"
        can :create, Admin::Collection
      end
    end
  end

  def custom_permissions(user=nil, session=nil)
    playlist_permissions
    unless full_login? and @user_groups.include? "administrator"
      cannot :read, MediaObject do |mediaobject|
        !(test_read(mediaobject.pid) && mediaobject.published?) && !test_edit(mediaobject.pid)
      end

      can :read, MasterFile do |master_file|
        can? :read, master_file.mediaobject
      end

      can :read, Derivative do |derivative|
        can? :read, derivative.masterfile.mediaobject
      end

      cannot :read, Admin::Collection unless full_login?

      if full_login?
        can :read, Admin::Collection do |collection|
          is_member_of?(collection)
        end

        unless (is_member_of_any_collection? or @user_groups.include? 'manager')
          cannot :read, Admin::Collection
        end

        can :update_access_control, MediaObject do |mediaobject|
          @user.in?(mediaobject.collection.managers) ||
            (is_editor_of?(mediaobject.collection) && !mediaobject.published?)
        end

        can :unpublish, MediaObject do |mediaobject|
          @user.in?(mediaobject.collection.managers)
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

        # Users logged in through LTI cannot share
        can :share, MediaObject
      end

      if is_api_request?
        can :manage, MediaObject
        can :manage, Admin::Collection
        can :manage, Avalon::ControlledVocabulary
      end

      cannot :update, MediaObject do |mediaobject|
        (not full_login?) || (!is_member_of?(mediaobject.collection)) ||
          ( mediaobject.published? && !@user.in?(mediaobject.collection.managers) )
      end

      cannot :destroy, MediaObject do |mediaobject|
        # non-managers can only destroy mediaobject if it's unpublished
        (not full_login?) || (!is_member_of?(mediaobject.collection)) ||
          ( mediaobject.published? && !@user.in?(mediaobject.collection.managers) )
      end

      cannot :destroy, Admin::Collection do |collection, other_user_collections=[]|
        (not full_login?) || !@user.in?(collection.managers)
      end
    end
  end

  def playlist_permissions
    if @user.id.present?
      can :manage, Playlist, user: @user
      # can :create, Playlist
    end
    can :read, Playlist, visibility: Playlist::PUBLIC

    playlist_item_permissions
    marker_permissions
  end

  def playlist_item_permissions
    if @user.id.present?
      can [:create, :update, :delete], PlaylistItem do |playlist_item|
        can? :manage, playlist_item.playlist
      end
    end
    can :read, PlaylistItem do |playlist_item|
      (can? :read, playlist_item.playlist) &&
      (can? :read, playlist_item.master_file)
    end
  end

  def marker_permissions
    if @user.id.present?
      can [:create, :update, :delete], AvalonMarker do |marker|
        can? :manage, marker.playlist_item.playlist
      end
    end
    can :read, AvalonMarker do |marker|
      (can? :read, marker.playlist_item.playlist) &&
      (can? :read, marker.playlist_item.master_file)
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

  def full_login?
    return @full_login unless @full_login.nil?
    @full_login = ( @session.present? and @session.has_key? :full_login ) ? @session[:full_login] : true
    @full_login
  end

  def is_api_request?
    @json_api_login ||= !!@session[:json_api_login] if @session.present?
    @json_api_login ||= false
    @json_api_login
  end

end
