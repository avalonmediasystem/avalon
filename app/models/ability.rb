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

class Ability
  # include CanCan::Ability
  include Hydra::Ability
  include Hydra::MultiplePolicyAwareAbility

  self.ability_logic += [:playlist_permissions,
                         :playlist_item_permissions,
                         :marker_permissions,
                         :encode_dashboard_permissions,
                         :timeline_permissions,
                         :checkout_permissions]

  def encode_dashboard_permissions
    can :read, :encode_dashboard if is_administrator?
  end

  def user_groups
    return @user_groups if @user_groups

    @user_groups = default_user_groups
    @user_groups |= current_user.groups if current_user and current_user.respond_to? :groups
    @user_groups |= ['registered'] unless current_user.new_record?
    @user_groups |= @options[:virtual_groups] if @options.present? and @options.has_key? :virtual_groups
    @user_groups |= [@options[:remote_ip]] if @options.present? and @options.has_key? :remote_ip
    @user_groups
  end

  def create_permissions(user=nil, session=nil)
    if full_login? || is_api_request?
      if is_administrator?
        can :manage, :all
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

    unless (full_login? || is_api_request?) and is_administrator?
      cannot :read, MediaObject do |media_object|
        !(test_read(media_object.id) && media_object.published?) && !test_edit(media_object.id)
      end

      can :read, MasterFile do |master_file|
        can? :read, master_file.media_object
      end

      can :read, Derivative do |derivative|
        can? :read, derivative.masterfile.media_object
      end

      cannot :read, Admin::Collection unless (full_login? || is_api_request?)

      if full_login? || is_api_request?
        can :read, Admin::Collection do |collection|
          is_member_of?(collection)
        end

        unless (is_member_of_any_collection? or @user_groups.include? 'manager')
          cannot :read, Admin::Collection
        end

        can :update_access_control, MediaObject do |media_object|
          @user.in?(media_object.collection.managers) ||
            (is_editor_of?(media_object.collection) && !media_object.published?)
        end

        can :unpublish, MediaObject do |media_object|
          @user.in?(media_object.collection.managers)
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

        can :destroy, ::Admin::CollectionPresenter do |collection|
          @user.in?(collection.managers)
        end

        can :inspect, MediaObject do |media_object|
          is_member_of?(media_object.collection)
        end

        can :show_progress, MediaObject do |media_object|
          is_member_of?(media_object.collection)
        end

        can [:edit, :destroy, :update], MasterFile do |master_file|
          can? :edit, master_file.media_object
        end

        # Users logged in through LTI cannot share
        can :share, MediaObject
      end

      # if is_api_request?
      #   can :manage, MediaObject
      #   can :manage, Admin::Collection
      #   can :manage, Avalon::ControlledVocabulary
      # end

      cannot :update, MediaObject do |media_object|
        (not (full_login? || is_api_request?)) || (!is_member_of?(media_object.collection)) ||
          ( media_object.published? && !@user.in?(media_object.collection.managers) )
      end

      cannot :destroy, MediaObject do |media_object|
        # non-managers can only destroy media_object if it's unpublished
        (not (full_login? || is_api_request?)) || (!is_member_of?(media_object.collection)) ||
          ( media_object.published? && !@user.in?(media_object.collection.managers) )
      end

      cannot :destroy, Admin::Collection do |collection, other_user_collections=[]|
        (not (full_login? || is_api_request?)) || !@user.in?(collection.managers)
      end

      can :intercom_push, MediaObject do |media_object|
        # anyone who can edit a media_object can also push it
        can? :edit, media_object
      end
    end
  end

  def playlist_permissions
    if @user.id.present?
      can :manage, Playlist, user: @user
      # can :create, Playlist
      can :duplicate, Playlist, visibility: Playlist::PUBLIC
      can :duplicate, Playlist do |playlist|
        playlist.valid_token?(@options[:playlist_token])
      end
    end
    can :read, Playlist, visibility: Playlist::PUBLIC
    can :read, Playlist do |playlist|
      playlist.valid_token?(@options[:playlist_token])
    end
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

  def timeline_permissions
    if @user.id.present?
      can :manage, Timeline, user: @user
      can :duplicate, Timeline, visibility: Timeline::PUBLIC
      can :duplicate, Timeline do |timeline|
        timeline.valid_token?(@options[:timeline_token])
      end
    end
    can :read, Timeline, visibility: Timeline::PUBLIC
    can :read, Timeline do |timeline|
      timeline.valid_token?(@options[:timeline_token])
    end
  end

  def checkout_permissions
    if @user.id.present?
      can :create, Checkout do |checkout|
        checkout.user == @user && can?(:read, checkout.media_object)
      end
      can :return, Checkout, user: @user
      can :return_all, Checkout, user: @user
      can :display_returned, Checkout, user: @user
      can :read, Checkout, user: @user
      can :update, Checkout, user: @user
      can :destroy, Checkout, user: @user
    end
  end

  def is_administrator?
    @user_groups.include?("administrator")
  end

  def is_member_of?(collection)
     is_administrator? ||
       @user.in?(collection.managers, collection.editors, collection.depositors)
  end

  def is_editor_of?(collection)
     is_administrator? ||
       @user.in?(collection.managers, collection.editors)
  end

  def is_member_of_any_collection?
    @user.id.present? && Admin::Collection.exists?("inheritable_edit_access_person_ssim" => @user.user_key)
  end

  def full_login?
    return @full_login unless @full_login.nil?
    @full_login = ( @options.present? and @options.has_key? :full_login ) ? @options[:full_login] : true
    @full_login
  end

  def is_api_request?
    @json_api_login ||= !!@options[:json_api_login] if @options.present?
    @json_api_login ||= false
    @json_api_login
  end

end
