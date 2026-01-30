# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
                         :checkout_permissions,
                         :administrative_permissions,
                         :repository_read_only_permissions]

  # Override to add handling of SpeedyAF proxy objects
  def edit_permissions
    super

    can [:edit, :update, :destroy], SpeedyAF::Base do |obj|
      test_edit(obj.id)
    end
  end

  def read_permissions
    super

    can :read, SpeedyAF::Base do |obj|
      test_read(obj.id)
    end
  end

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

      if is_member_of_any_collection? || is_member_of_any_unit?
        can :create, MediaObject
      end

      if is_manager?
        can :create, Admin::Collection
      end

      if is_manager_of_any_unit?
        can :create, Admin::Collection
      end

      if is_unit_admin?
        can :create, Admin::Unit
      end
    end
  end

  def custom_permissions(user=nil, session=nil)

    unless (full_login? || is_api_request?) and is_administrator?
      cannot :read, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
        !(test_read(media_object.id) && media_object.published?) && !test_edit(media_object.id)
      end

      can :read, [MasterFile, SpeedyAF::Proxy::MasterFile] do |master_file|
        can? :read, master_file.media_object
      end

      can :read, [Derivative, SpeedyAF::Proxy::Derivative] do |derivative|
        can? :read, derivative.masterfile.media_object
      end

      cannot :read, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] unless (full_login? || is_api_request?)

      cannot :read, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] unless (full_login? || is_api_request?)

      if full_login? || is_api_request?
        can [:read, :items], [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection|
          is_member_of?(collection)
        end

        can [:read, :items], [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
          is_admin_of?(unit)
        end

        unless has_administrative_access?
          cannot :read, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection]
          cannot :read, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit]
        end

        can :update_access_control, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
          is_manager_of?(media_object.collection) ||
            (is_editor_of?(media_object.collection) && !media_object.published?)
        end

        can :unpublish, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
          is_manager_of?(media_object.collection)
        end

        can :move, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
          is_manager_of?(media_object.collection)
        end

        can :update, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection|
          is_manager_of?(collection)
        end

        can :update_unit, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection|
          is_manager_of?(collection)
        end

        can :update_access_control, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection|
          is_manager_of?(collection)
        end

        can :update_managers, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection|
          is_manager_of?(collection)
        end

        can :update_editors, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection|
          is_manager_of?(collection)
        end

        can :update_depositors, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection|
          is_editor_of?(collection)
        end

        can :destroy, ::Admin::CollectionPresenter do |collection|
          is_manager_of?(collection)
        end

        can :update, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
          is_admin_of?(unit)
        end

        can :update_access_control, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
          is_admin_of?(unit)
        end

        can :update_unit_admins, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
          is_admin_of?(unit)
        end

        can :update_managers, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
          is_admin_of?(unit)
        end

        can :update_editors, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
          is_manager_of_unit?(unit)
        end

        can :update_depositors, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
          is_editor_of_unit?(unit)
        end

        can :destroy, ::Admin::UnitPresenter do |unit|
          is_admin_of?(unit)
        end

        can :inspect, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
          is_member_of?(media_object.collection)
        end

        can :show_progress, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
          is_member_of?(media_object.collection)
        end

        can [:edit, :destroy, :update], [MasterFile, SpeedyAF::Proxy::MasterFile] do |master_file|
          can? :edit, master_file.media_object
        end

        can :download, [MasterFile, SpeedyAF::Proxy::MasterFile] do |master_file|
          is_manager_of?(master_file.media_object.collection)
        end

        # Users logged in through LTI cannot share
        can :share, [MediaObject, SpeedyAF::Proxy::MediaObject]
      end

      # if is_api_request?
      #   can :manage, MediaObject
      #   can :manage, Admin::Collection
      #   can :manage, Avalon::ControlledVocabulary
      # end

      cannot :update, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
        (not (full_login? || is_api_request?)) || (!is_member_of?(media_object.collection)) ||
          ( media_object.published? && !is_manager_of?(media_object.collection) )
      end

      cannot :destroy, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
        # non-managers can only destroy media_object if it's unpublished
        (not (full_login? || is_api_request?)) || (!is_member_of?(media_object.collection)) ||
          ( media_object.published? && !is_manager_of?(media_object.collection) )
      end

      cannot :move, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
        (not (full_login? || is_api_request?)) || !is_manager_of?(media_object.collection)
      end

      cannot :update, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection|
        # Editors and Depositors should not be able to edit collection level information
        !is_manager_of?(collection)
      end

      cannot :destroy, [Admin::Collection, SpeedyAF::Proxy::Admin::Collection] do |collection, other_user_collections=[]|
        (not (full_login? || is_api_request?)) || !is_manager_of?(collection)
      end

      cannot :update, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
        !is_admin_of?(unit)
      end

      cannot :destroy, [Admin::Unit, SpeedyAF::Proxy::Admin::Unit] do |unit|
        (not (full_login? || is_api_request?)) || !@user.in?(unit.unit_admins)
      end

      can :intercom_push, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
        # anyone who can edit a media_object can also push it
        can? :edit, media_object
      end

      can :json_update, [MediaObject, SpeedyAF::Proxy::MediaObject] do |media_object|
        # anyone who can edit a media_object can also update it via the API
        is_api_request? && can?(:edit, media_object)
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
      can :read, Checkout, user: @user
      can :update, Checkout, user: @user
      can :destroy, Checkout, user: @user
    end
  end

  def administrative_permissions
    if has_administrative_access?
      can :discover_unpublished, MediaObject
      can :read, :administrative_facets
    end
  end

  def repository_read_only_permissions
    if Settings.repository_read_only_mode
      cannot [:create, :edit, :update, :destroy, :update_access_control, :unpublish, :intercom_push], [MediaObject, SpeedyAF::Proxy::MediaObject]
      cannot [:create, :edit, :update, :destroy], [MasterFile, SpeedyAF::Proxy::MasterFile]
      cannot [:create, :edit, :update, :destroy], [Derivative, SpeedyAF::Proxy::Derivative]
      cannot [:create, :edit, :update, :destroy, :update_unit, :update_access_control, :update_managers, :update_editors, :update_depositors], [Admin::Collection, SpeedyAF::Proxy::Admin::Collection, Admin::CollectionPresenter]
      cannot [:create, :edit, :update, :destroy], SpeedyAF::Base
      cannot [:create, :edit, :update, :destroy, :update_access_control, :update_unit_admins, :update_managers, :update_editors, :update_depositors], [Admin::Unit, SpeedyAF::Proxy::Admin::Unit, Admin::UnitPresenter]
    end
  end

  def is_administrator?
    @user_groups.include?("administrator")
  end

  def is_manager?
    @user_groups.include?("manager")
  end

  def is_unit_admin?
    @user_groups.include?("unit_administrator")
  end

  def is_admin_of?(unit)
    is_administrator? ||
      @user.in?(unit.unit_admins)
  end

  def is_member_of?(collection)
     is_administrator? ||
       @user.in?(collection.managers, collection.editors, collection.depositors) ||
       @user.in?(collection.inherited_managers, collection.inherited_editors, collection.inherited_depositors)
  end

  def is_manager_of?(collection)
    is_administrator? ||
      @user.in?(collection.managers) ||
      @user.in?(collection.inherited_managers)
  end

  def is_editor_of?(collection)
     is_administrator? ||
       @user.in?(collection.editors_and_managers) ||
       @user.in?(collection.unit.editors_managers_and_unit_admins)
  end

  def is_manager_of_unit?(unit)
    is_administrator? ||
      @user.in?(unit.unit_admins) ||
      @user.in?(unit.managers)
  end

  def is_editor_of_unit?(unit)
    is_administrator? ||
      @user.in?(unit.editors_managers_and_unit_admins)
  end

  def is_member_of_any_collection?
    @user.id.present? && Admin::Collection.exists?("inheritable_edit_access_person_ssim" => @user.user_key)
  end

  def is_member_of_any_unit?
    @user.id.present? && Admin::Unit.exists?("inheritable_edit_access_person_ssim" => @user.user_key)
  end

  def is_manager_of_any_unit?
    @user.id.present? && (Admin::Unit.exists?("unit_administrators_ssim" => @user.user_key) || Admin::Unit.exists?("collection_managers_ssim" => @user.user_key))
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

  def has_administrative_access?
    is_administrator? || is_unit_admin? || is_manager? || is_member_of_any_unit? || is_member_of_any_collection?
  end
end
