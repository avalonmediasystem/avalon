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

# Controller class for the AvalonMarker Model
# Implements show, create, update, and delete
class AvalonMarkerController < ApplicationController
  # after_action:
  def initialize
    @not_found_messages = { marker: 'Marker Not Found',
                            master_file: 'Master File Not Found',
                            playlist_item: 'Playlist Item Not Found' }
    @attr_keys = [:title, :start_time]
  end

  # Finds the marker based on passed uuid and renders the marker's json
  # @param [Hash] params the parameters used by the controller
  # @option params [String] :id the uuid of the marker you wish to render
  # @example Rails Console Call To Show Marker that is resolved by AvalonMarker.where(uuid: '56')[0]
  #    app.get('/avalon_marker/56')
  def show
    lookup_marker
    render json: @marker.pretty_annotation
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
    marker_params = params['avalon_marker']
    render json: { message: 'Masterfile Not Supplied' }, status: 400 and return if marker_params[:master_file].nil?
    render json: { message: 'Playlist Item Not Supplied' }, status: 400 and return if marker_params[:playlist_item].nil?
    mf = MasterFile.where(id: marker_params[:master_file])[0]
    render json: { message: @not_found_messages[:master_file] }, status: 400 and return if mf.nil?
    pi = PlaylistItem.where(id: marker_params[:playlist_item])[0]
    render json: { message: @not_found_messages[:playlist_item] }, status: 400 and return if pi.nil?

    @marker = AvalonMarker.create(master_file: mf, playlist_item: pi)
    selected_key_updates

    if @marker.persisted?
      render json: { id: @marker.id, marker: {title: @marker.title, start_time: @marker.start_time}, message: "Add marker to playlist item was successful." }, status: 201 and return
    else
      render json: { message: @marker.errors.full_messages }, status: 400 and return
    end
  end

  # Updates a marker and renders it as JSON
  # @param [Hash] params the parameters used for updating a marker
  # @option params [String] :id the id of the marker to update
  # @option params [String] :title the title to use for the marker
  # @option params [String] :start_time the time point the marker
   # @example Rails Console command to update the title of the marker with a uuid of 56 to be 'Hail'
  #    app.put('/avalon_marker/56', {title: 'Hail'})
  def update
    lookup_marker
    selected_key_updates
    render json: {id: @marker.id, marker: @marker.pretty_annotation}
  end

  # Destroy a marker based on uuid
  # @param [Hash] params the parameters used by the controller
  # @option params [String] :id the uuid of the marker you wish to destroy
  # @example Rails Console command to destroy the marker with an uuid of 56
  #    app.delete('/avalon_marker/56')
  def destroy
    lookup_marker
    @marker.destroy
    render json: { action: 'destroy', id: @marker.id, success: true }
  end

  # Looks up a marker using the id key in params and sets @marker
  def lookup_marker
    @marker = AvalonMarker.where(uuid: params[:id])[0]
    @marker = AvalonMarker.where(id: params[:id])[0] if @marker.nil?
    not_found if @marker.nil?
  end

  # Using the params passed into the controller, update the marker and reload it
  def selected_key_updates
    marker_params = params['avalon_marker']
    marker_params[:start_time] = time_str_to_milliseconds marker_params[:start_time] if marker_params[:start_time].present?
    updates = {}
    @attr_keys.each do |key|
      updates[key] = marker_params[key] unless marker_params[key].nil?
    end
    @marker.update(updates) unless updates.keys.empty?
    @marker.reload
  end

  # Raises a 404 error when a marker or master_file cannot be Found
  # @param [Symbol] The object that cannot be found (:marker or :master_file)
  # @raise ActionController::RoutingError resolves as a 404 in browser
  def not_found(item: :marker)
    raise ActionController::RoutingError.new(@not_found_messages[item])
  end

  private

  # Returns milliseconds from a time string of format h:m:s.s or m:s.s or s.s
  # @param [String] The time string
  # @return [float] the time string converted to milliseconds
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
