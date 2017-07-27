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
  before_action :authenticate_user!, except: [:show, :refresh_info]
  load_and_authorize_resource
  skip_load_and_authorize_resource only: [:import_variations_playlist, :refresh_info]
  before_action :get_all_playlists, only: [:index, :edit, :update]

  # GET /playlists
  def index
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
          playlist.visibility =='private'? '<span class="fa fa-lock fa-lg"></span> Only me' : '<span class="fa fa-globe fa-lg"></span> Public',
          "<span title='#{playlist.created_at.utc.iso8601}'>#{view_context.time_ago_in_words(playlist.created_at)}</span>",
          "<span title='#{playlist.updated_at.utc.iso8601}'>#{view_context.time_ago_in_words(playlist.updated_at)}</span>",
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
  end

  # GET /playlists/new
  def new
    @playlist = Playlist.new
  end

  # GET /playlists/1/edit
  def edit
    # We are already editing our playlist, we don't need it to show up in this array as well
    @playlists.delete( @playlist )
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
  def replicate
    old_playlist = Playlist.find(params['old_playlist_id'])
    @playlist = Playlist.new(playlist_params.merge(user: current_user))
    if @playlist.save

      #copy items
      old_playlist.items.each do |item|
        copy_item = item.replicate!
        @playlist.items << copy_item
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

  def update_multiple
    if request.request_method=='DELETE'
      PlaylistItem.where(id: params[:clip_ids]).to_a.map(&:destroy)
    elsif params[:new_playlist_id].present? and params[:clip_ids]
      @new_playlist = Playlist.find(params[:new_playlist_id])
      pis = PlaylistItem.where(id: params[:clip_ids])
      @new_playlist.items += pis
      @playlist.items -= pis
      @new_playlist.save!
      @playlist.save!
    end
    redirect_to edit_playlist_path(@playlist), notice: 'Playlist was successfully updated.'
  end

  # DELETE /playlists/1
  def destroy
    @playlist.destroy
    redirect_to playlists_url, notice: 'Playlist was successfully destroyed.'
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

  private

  # Use callbacks to share common setup or constraints between actions.
  def get_all_playlists
    @playlists = Playlist.for_ability(current_ability).to_a
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

  def refresh_info
    respond_to do |format|
      format.js
    end
  end
end
