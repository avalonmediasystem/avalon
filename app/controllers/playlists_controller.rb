# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

require 'avalon/variations_playlist_importer'

class PlaylistsController < ApplicationController
  include ConditionalPartials

  before_action :authenticate_user!, except: [:show, :refresh_info]
  load_and_authorize_resource except: [:import_variations_playlist, :refresh_info, :duplicate, :show, :index]
  load_resource only: [:show, :refresh_info]
  authorize_resource only: [:index]
  before_action :get_all_other_playlists, only: [:edit]

  helper_method :access_token_url

  def self.is_owner ctx
    ctx.current_ability.is_administrator? || (ctx.current_user == ctx.instance_variable_get('@playlist').user)
  end
  def self.is_lti_session ctx
    ctx.user_session.present? && ctx.user_session[:lti_group].present?
  end

  is_owner_or_not_lti = proc { |ctx| self.is_owner(ctx) || !self.is_lti_session(ctx) }
  is_owner_or_lti = proc { |ctx| (Avalon::Authentication::Providers.any? {|p| p[:provider] == :lti } &&self.is_owner(ctx)) || self.is_lti_session(ctx) }

  add_conditional_partial :share, :share, partial: 'share_resource', if: is_owner_or_not_lti
  add_conditional_partial :share, :lti_url, partial: 'lti_url',  if: is_owner_or_lti

  # GET /playlists
  def index
    # Cancan's load_resource doesn't work here anymore because we added a can with a block
    @playlists = Playlist.where( user_id: current_user )
  end

  # POST /playlists/paged_index
  def paged_index
    # Playlists for index page are loaded dynamically by jquery datatables javascript which
    # requests the html for only a limited set of rows at a time.
    playlists = Playlist.where(user_id: current_user.id)
    recordsTotal = playlists.count
    columns = ['title','size','visibility','created_at','updated_at','actions']
    playlistsFiltered = playlists.where("title LIKE ?", "%#{request.params['search']['value']}%")
    if columns[request.params['order']['0']['column'].to_i] != 'size'
      playlistsFiltered = playlistsFiltered.order("lower(#{columns[request.params['order']['0']['column'].to_i]}) #{request.params['order']['0']['dir']}")
      pagedPlaylists = playlistsFiltered.offset(request.params['start']).limit(request.params['length'])
    else
      # sort by size (item count): decorate list with playlistitem count then sort and undecorate
      decorated = playlistsFiltered.collect{|p| [ p.items.size, p ]}
      decorated.sort!
      playlistsFiltered = decorated.collect{|p| p[1]}
      playlistsFiltered.reverse! if request.params['order']['0']['dir']=='desc'
      pagedPlaylists = playlistsFiltered.slice(request.params['start'].to_i, request.params['length'].to_i)
    end
    response = {
      "draw": request.parameters['draw'],
      "recordsTotal": recordsTotal,
      "recordsFiltered": playlistsFiltered.count,
      "data": pagedPlaylists.collect do |playlist|
        copy_button = view_context.button_tag( type: 'button', data: { playlist: playlist },
          class: 'copy-playlist-button btn btn-default btn-xs') do
          "<span class='fa fa-clone'> Copy </span>".html_safe
        end
        edit_button = view_context.link_to(edit_playlist_path(playlist), class: 'btn btn-default btn-xs') do
          "<span class='fa fa-edit'> Edit</span>".html_safe
        end
        delete_button = view_context.link_to(playlist_path(playlist), method: :delete, class: 'btn btn-xs btn-danger btn-confirmation', data: {placement: 'bottom'}) do
          "<span class='fa fa-times'> Delete</span>".html_safe
        end
        [
          view_context.link_to(playlist.title, playlist_path(playlist), title: playlist.comment),
          "#{playlist.items.size} items",
          view_context.human_friendly_visibility(playlist.visibility),
          "<span title='#{playlist.created_at.utc.iso8601}'>#{view_context.time_ago_in_words(playlist.created_at)} ago</span>",
          "<span title='#{playlist.updated_at.utc.iso8601}'>#{view_context.time_ago_in_words(playlist.updated_at)} ago</span>",
          "#{copy_button} #{edit_button} #{delete_button}"
        ]
      end
    }
    respond_to do |format|
      format.json do
        render json: response
      end
    end
  end

  # GET /playlists/1
  def show
    @playlist_token = params[:token]
    current_ability.options[:playlist_token] = @playlist_token
    authorize! :read, @playlist
  end

  # GET /playlists/new
  def new
    @playlist = Playlist.new
  end

  # GET /playlists/1/edit
  def edit
  end

  # POST /playlists
  def create
    @playlist = Playlist.new(playlist_params.merge(user: current_user))
    if @playlist.save
      respond_to do |format|
        format.html do
          redirect_to @playlist, notice: 'Playlist was successfully created.'
        end
        format.json do
          render json: @playlist
        end
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:error] = @playlist.errors.full_messages.to_sentence
          render action: 'new'
        end
        format.json do
          render json: {errors: @playlist.errors}
        end
      end
    end
  end

  # POST /playlists
  def duplicate
    old_playlist = Playlist.find(params['old_playlist_id'])
    authorize! :duplicate, old_playlist, message: "You do not have sufficient privledges to copy this item"
    @playlist = Playlist.new(playlist_params.merge(user: current_user))
    if @playlist.save

      #copy items
      old_playlist.items.each do |item|
        next if item.clip.master_file.nil?
        copy_item = item.duplicate!
        copy_item.playlist_id  = @playlist.id
        copy_item.save!
        copy_item.move_to_bottom
      end

      respond_to do |format|
        format.json do
          render json: { playlist: @playlist, path: edit_playlist_path(@playlist) }
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {errors: @playlist.errors}
        end
      end
    end
  end


  # PATCH/PUT /playlists/1
  def update
    if update_playlist(@playlist)
      respond_to do |format|
        format.html do
          redirect_to edit_playlist_path(@playlist), notice: 'Playlist was successfully updated.'
        end
        format.json do
          render json: @playlist
        end
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:error] = "There are errors with your submission.  #{@playlist.errors.full_messages.join(', ')}"
          render action: 'edit'
        end
        format.json do
          render json: {errors: @playlist.errors}
        end
      end
    end
  end

  # PATCH/PUT /playlists/1/update_multiple
  def update_multiple
    if request.request_method=='DELETE'
      PlaylistItem.where(id: params[:clip_ids]).to_a.map(&:destroy)
    elsif params[:new_playlist_id].present? and params[:clip_ids]
      @new_playlist = Playlist.find(params[:new_playlist_id])
      playlist_items = PlaylistItem.where(id: params[:clip_ids])
      playlist_items.each do |item|
        next if item.clip.master_file.nil?
        if (params[:action_type] == 'copy_to_playlist')
          item = item.duplicate!
        end
        item.playlist_id = @new_playlist.id
        item.save!
        item.move_to_bottom
      end
      @playlist.save!
      @new_playlist.save!
    end
    redirect_to edit_playlist_path(@playlist), notice: 'Playlist was successfully updated.'
  end

  # PATCH/PUT /playlists/1/regenerate_access_token
  def regenerate_access_token
    @playlist.access_token = nil
    @playlist.save!
    render json: { access_token_url: access_token_url(@playlist) }
  end

  # DELETE /playlists/1
  def destroy
    @playlist.destroy
    redirect_to playlists_url, notice: 'Playlist was successfully destroyed.'
  end

  def access_token_url(playlist)
    playlist_url(playlist, token: playlist.access_token)
  end

  def import_variations_playlist
    playlist_file = params[:Filedata]
    if params.key?(:skip_errors)
      t = Tempfile.new('v2p')
      t.write(session.delete(:variations_playlist))
      t.flush.rewind
      playlist_file = t
    end
    playlist = Avalon::VariationsPlaylistImporter.new.import_playlist(playlist_file, current_user, params.key?(:skip_errors))
    if playlist.persisted?
      redirect_to playlist, notice: 'Variations playlist was successfully imported.'
    else
      session[:variations_playlist] = File.read(params[:Filedata].tempfile)
      render 'import_variations_playlist', locals: { playlist: playlist }
    end
  rescue StandardError => e
    redirect_to playlists_url, flash: { error: "Import failed: #{e.message}" }
  end

  def refresh_info
    @playlist_token = params[:token]
    current_ability.options[:playlist_token] = @playlist_token
    @position = params[:position]
    @playlist_item = @playlist.items.where(position: @position.to_i).first
    authorize! :read, @playlist_item
    render formats: :js
  end

  private

  def get_all_other_playlists
    @playlists = Playlist.where( user_id: current_user ).where.not( id: @playlist )
  end

  # Only allow a trusted parameter "white list" through.
  def playlist_params
    params.require(:playlist).permit(:title, :comment, :visibility, :clip_ids, items_attributes: [:id, :position])
  end

  def update_playlist(playlist)
    playlist.assign_attributes(playlist_params)
    reorder_items(playlist)
    playlist.save
  end

  # This updates the positions of the playlist items
  def reorder_items(playlist)
    # we have to do a sort_by, not order, because the updated attributes have not been saved.
    changed_playlist, new, changed_position, unchanged = playlist.items.
      sort_by(&:position).
      group_by do |item|
	if item.playlist_id_was != item.playlist_id
	  :changed_playlist
	elsif item.position_was.nil?
	  :new
	elsif item.position_was != item.position
	  :changed_position
	else
	  :unchanged
	end
    end.values_at(:changed_playlist, :new, :changed_position, :unchanged).map(&:to_a)
    # items that will be in this playlist
    unmoved_items = unchanged
    # place items whose positions were specified
    changed_position.map {|item| unmoved_items.insert(item.position - 1, item)}
    # add new items at the end
    unmoved_items = unmoved_items + new
    # calculate positions
    unmoved_items.compact.
      select {|item| item.playlist_id_was == item.playlist_id}.
      each_with_index do |item, position|
	item.position = position + 1
      end

    # items that have moved to another playlist
    changed_playlist.select {|item| item.playlist_id_was != item.playlist_id}.each do |item|
      item.position = nil
    end
  end
end
