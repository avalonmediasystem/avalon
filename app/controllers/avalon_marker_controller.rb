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

# Controller class for the AvalonMarker Model
# Implements show, create, update, and delete
class AvalonMarkerController < ApplicationController
  before_action :set_marker, except: [:create]
  before_action :authenticate_user!

  # Finds the marker based on passed id or uuid and renders the marker's json
  # @param [Hash] params the parameters used by the controller
  # @option params [String] :id the id or uuid of the marker you wish to render
  # @example Rails Console Call To Show Marker that is resolved by AvalonMarker.where(uuid: '56')[0]
  #    app.get('/avalon_marker/56')
  def show
    render json: @marker.to_json
  end

  # Creates a marker and renders it as JSON
  # @param [Hash] params the parameters used for creating a marker
  # @option params [String] :master_file the pid of the MasterFile to be used for this marker's source
  # @option params [String] :playlist_item the pid of the PlaylistItem to which this marker belongs
  # @option params [String] :title the title to use for the marker, defaults the the MasterFile title
  # @option params [String] :start_time the time point the marker begins, defaults to 0
  # @example Rails Console command to create a marker based of the MasterFile whose pid is avalon:20 and default values for all other fields in the marker
  #    app.post('/avalon_marker/', {master_file: 'avalon:20'})
  def create
    marker_params
    unless can? :update, @marker_params[:playlist_item]
      render json: { message: 'You are not authorized to perform this action.' }, status: 401 and return
    end
    @marker = AvalonMarker.create(@marker_params)
    if @marker.persisted?
      render json: @marker.to_json.merge(message: 'Add marker to playlist item was successful.'), status: 201 and return
    else
      render json: { message: @marker.errors.full_messages }, status: 400 and return
    end
  rescue StandardError => error
    render json: { message: "Marker was not created: #{error.message}" }, status: 500 and return
  end

  # Updates a marker and renders it as JSON
  # @param [Hash] params the parameters used for updating a marker
  # @option params [String] :id the id of the marker to update
  # @option params [String] :title the title to use for the marker
  # @option params [String] :start_time the time point the marker
  # @example Rails Console command to update the title of the marker with a uuid of 56 to be 'Hail'
  #    app.put('/avalon_marker/56', {title: 'Hail'})
  def update
    unless can? :update, @marker
      render json: { message: 'You are not authorized to perform this action.' }, status: 401 and return
    end
    if @marker.update(marker_params)
      render json: @marker.to_json, status: 201 and return
    else
      render json: { message: "Marker was not updated", errors: @marker.errors.full_messages }, status: :unprocessable_entity
    end
  rescue StandardError => error
    render json: { message: "Marker was not updated", errors: error.message }, status: 500 and return
  end

  # Destroy a marker based on uuid
  # @param [Hash] params the parameters used by the controller
  # @option params [String] :id the uuid of the marker you wish to destroy
  # @example Rails Console command to destroy the marker with an uuid of 56
  #    app.delete('/avalon_marker/56')
  def destroy
    unless can? :delete, @marker
      render json: { message: 'You are not authorized to perform this action.' }, status: 401 and return
    end
    @marker.destroy
    render json: @marker.to_json.merge(action: 'destroy', success: true)
  rescue StandardError => error
    render json: { message: "Marker was not destroyed: #{error.message}" }, status: 500 and return
  end

  private

  # Looks up a marker using the id key in params and sets @marker
  def set_marker
    @marker = AvalonMarker.find(params[:id]) || AvalonMarker.find_by_uuid(params[:id])
  rescue StandardError => error
    render json: { message: "Marker not found: #{error.message}" }, status: 500 and return
  end

  def marker_params
    @marker_params = params.require(:marker).permit(:master_file_id, :playlist_item_id, :title, :start_time)
    @marker_params[:start_time] = time_str_to_milliseconds @marker_params[:start_time] if @marker_params[:start_time].present?
    @marker_params[:playlist_item] = PlaylistItem.find(@marker_params.delete(:playlist_item_id)) if @marker_params[:playlist_item_id].present?
    @marker_params[:master_file] = MasterFile.find(@marker_params.delete(:master_file_id)) if @marker_params[:master_file_id].present?
    @marker_params
  end

end
