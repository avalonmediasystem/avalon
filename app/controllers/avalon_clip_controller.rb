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

# Controller class for the AvalonClip Model
# Implements show, create, update, and delete
class AvalonClipController < ApplicationController
  # after_action:
  def initialize
    @not_found_messages = { clip: 'Clip Not Found',
                            master_file: 'Master File Not Found' }
    @attr_keys = [:title, :start_time, :end_time, :comment]
  end

  # Finds the clip based on passed uuid and renders the clip's json
  # @param [Hash] params the parameters used by the controller
  # @option params [String] :id the uuid of the clip you wish to render
  # @example Rails Console Call To Show Clip that is resolved by AvalonClip.where(uuid: '56')[0]
  #    app.get('/avalon_clip/56')
  def show
    lookup_clip
    render json: @clip.pretty_annotation
  end

  # Creates a clip and renders it as JSON
  # @param [Hash] params the parameters used for creating a clip
  # @option params [String] :master_file the pid of the MasterFile to be used for this clip's source
  # @option params [String] :title the title to use for the clip, defaults the the MasterFile title
  # @option params [String] :start_time the time point the clip begins, defaults to 0
  # @option params [String] :end_time the time point the clip ends, defaults to the duration of the MasterFile
  # @option params [String] :comment Any comment the user wishes to supply, defaults to nil
  # @example Rails Console command to create a clip based of the MasterFile whose pid is avalon:20 and default values for all other fields in the clip
  #    app.post('/avalon_clip/', {master_file: 'avalon:20'})
  def create
    fail ArgumentError, 'Master File Not Supplied' if params[:master_file].nil?
    begin
      mf = MasterFile.find(params[:master_file])
    rescue
      mf = nil
    end
    not_found(item: :master_file) if mf.nil?
    @clip = AvalonClip.create(master_file: mf)
    selected_key_updates
    render json: @clip.pretty_annotation
  end

  # Updates a clip and renders it as JSON
  # @param [Hash] params the parameters used for updating a clip
  # @option params [String] :id the id of the clip to update
  # @option params [String] :title the title to use for the clip
  # @option params [String] :start_time the time point the clip
  # @option params [String] :end_time the time point the clip ends
  # @option params [String] :comment Any comment the user wishes to supply
  # @example Rails Console command to update the title of the clip with a uuid of 56 to be 'Hail'
  #    app.put('/avalon_clip/56', {title: 'Hail'})
  def update
    lookup_clip
    selected_key_updates
    render json: @clip.pretty_annotation
  end

  # Destroy a clip based on uuid
  # @param [Hash] params the parameters used by the controller
  # @option params [String] :id the uuid of the clip you wish to destroy
  # @example Rails Console command to destroy the clip with an uuid of 56
  #    app.delete('/avalon_clip/56')
  def destroy
    lookup_clip
    id = @clip.uuid
    @clip.destroy
    render json: { action: 'destroy', id: id, success: true }
  end

  # Looks up a clip using the id key in params and sets @clip
  def lookup_clip
    @clip = AvalonClip.where(uuid: params[:id])[0]
    not_found if @clip.nil?
  end

  # Using the params passed into the controller, update the clip and reload it
  def selected_key_updates
    updates = {}
    @attr_keys.each do |key|
      updates[key] = params[key] unless params[key].nil?
    end
    @clip.update(updates) unless updates.keys.empty?
    @clip.reload
  end

  # Raises a 404 error when a clip or master_file cannot be Found
  # @param [Symbol] The object that cannot be found (:clip or :master_file)
  # @raise ActionController::RoutingError resolves as a 404 in browser
  def not_found(item: :clip)
    raise ActionController::RoutingError.new(@not_found_messages[item])
  end
end
