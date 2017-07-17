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

class PlaylistItemsController < ApplicationController
  before_action :set_playlist, only: [:create, :update]
  before_action :authenticate_user!

  # POST /playlists/1/items
  def create
    unless (can? :create, PlaylistItem) && (can? :edit, @playlist)
      render json: { message: 'You are not authorized to perform this action.' }, status: 401 and return
    end
    title =  playlist_item_params[:title]
    comment = playlist_item_params[:comment]
    start_time = time_str_to_milliseconds playlist_item_params[:start_time]
    end_time = time_str_to_milliseconds playlist_item_params[:end_time]
    clip = AvalonClip.new(master_file: MasterFile.find(playlist_item_params[:master_file_id]))
    clip.title = title
    clip.comment = comment
    clip.start_time = start_time
    clip.end_time = end_time
    unless clip.valid?
      render json: { message: clip.errors.full_messages }, status: 400 and return
    end
    unless clip.save
      render json: { message: "Item was not created: #{clip.errors.full_messages}" }, status: 500 and return
    end
    if PlaylistItem.create(playlist: @playlist, clip: clip)
      render json: { message: "Add to playlist was successful. See it: #{view_context.link_to("here", playlist_url(@playlist))}" }, status: 201 and return
    end
  rescue StandardError => error
    render json: { message: "Item was not created: #{error.message}"}, status: 500 and return
  end

  def update
    playlist_item = PlaylistItem.find(params['id'])
    unless (can? :update, playlist_item)
      render json: { message: 'You are not authorized to perform this action.' }, status: 401 and return
    end
    clip = AvalonClip.find(playlist_item.clip.id)
    clip.title =  playlist_item_params[:title]
    clip.comment = playlist_item_params[:comment]
    clip.start_time = time_str_to_milliseconds playlist_item_params[:start_time]
    clip.end_time = time_str_to_milliseconds playlist_item_params[:end_time]
    if clip.save
      render json: { message: "Item was updated successfully." }, status: 201 and return
    else
      render json: { message: "Item was not updated: #{clip.errors.full_messages.join(', ')}" }, status: 500 and return
    end
  rescue StandardError => error
    render json: { message: "Item was not updated: #{error.message}" }, status: 500 and return
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_playlist
    @playlist = Playlist.find(params[:playlist_id])
  end

  def playlist_item_params
    params.require(:playlist_item).permit(:title, :comment, :master_file_id, :start_time, :end_time)
  end

  def time_str_to_milliseconds value
    if value.is_a?(Numeric)
      value.floor
    elsif value.is_a?(String)
      result = 0
      segments = value.split(/:/).reverse
      begin
        segments.each_with_index { |v,i| result += i > 0 ? Float(v) * (60**i) * 1000 : (Float(v) * 1000) }
        result.to_i
      rescue
        return value
      end
    else
      value
    end
  end

end
