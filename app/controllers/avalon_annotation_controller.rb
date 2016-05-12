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

# Controller class for the AvalonAnnotation Model
# Implements show, create, update, and delete
class AvalonAnnotationController < ApplicationController
  # after_action:
  def initialize
    @not_found_messages = { annotation: 'Annotation Not Found',
                            master_file: 'Master File Not Found' }
    @attr_keys = [:title, :start_time, :end_time, :comment]
  end

  # Finds the annotation based on passed uuid and renders the annotation's json
  # @param [Hash] params the parameters used by the controller
  # @option params [String] :id the uuid of the annotation you wish to render
  # @example Rails Console Call To Show Annotation that is resolved by AvalonAnnotation.where(uuid: '56')[0]
  #    app.get('/avalon_annotation/56')
  def show
    lookup_annotation
    render json: @annotation.pretty_annotation
  end

  # Creates an annotation and renders it as JSON
  # @param [Hash] params the parameters used for creating an annotation
  # @option params [String] :master_file the pid of the MasterFile to be used for this annotation's source
  # @option params [String] :title the title to use for the annotation, defaults the the MasterFile title
  # @option params [String] :start_time the time point the annotation begins, defaults to 0
  # @option params [String] :end_time the time point the annotation ends, defaults to the duration of the MasterFile
  # @option params [String] :comment Any comment the user wishes to supply, defaults to nil
  # @example Rails Console command to create an annotation based of the MasterFile whose pid is avalon:20 and default values for all other fields in the annotation
  #    app.post('/avalon_annotation/', {master_file: 'avalon:20'})
  def create
    fail ArgumentError, 'Master File Not Supplied' if params[:master_file].nil?
    begin
      mf = MasterFile.find(params[:master_file])
    rescue
      mf = nil
    end
    not_found(item: :master_file) if mf.nil?
    @annotation = AvalonAnnotation.create(master_file: mf)
    selected_key_updates
    render json: @annotation.pretty_annotation
  end

  # Updates an annotation and renders it as JSON
  # @param [Hash] params the parameters used for updating an annotation
  # @option params [String] :id the id of the annotation to update
  # @option params [String] :title the title to use for the annotation
  # @option params [String] :start_time the time point the annotation
  # @option params [String] :end_time the time point the annotation ends
  # @option params [String] :comment Any comment the user wishes to supply
  # @example Rails Console command to update the title of the annotation with a uuid of 56 to be 'Hail'
  #    app.put('/avalon_annotation/56', {title: 'Hail'})
  def update
    lookup_annotation
    selected_key_updates
    render json: @annotation.pretty_annotation
  end

  # Destroy an annotation based on uuid
  # @param [Hash] params the parameters used by the controller
  # @option params [String] :id the uuid of the annotation you wish to destroy
  # @example Rails Console command to destroy the annotation with an uuid of 56
  #    app.delete('/avalon_annotation/56')
  def destroy
    lookup_annotation
    id = @annotation.uuid
    @annotation.destroy
    render json: { action: 'destroy', id: id, success: true }
  end

  # Looks up an annotation using the id key in params and sets @annotation
  def lookup_annotation
    @annotation = AvalonAnnotation.where(uuid: params[:id])[0]
    not_found if @annotation.nil?
  end

  # Using the params passed into the controller, update the annotation and reload it
  def selected_key_updates
    updates = {}
    @attr_keys.each do |key|
      updates[key] = params[key] unless params[key].nil?
    end
    @annotation.update(updates) unless updates.keys.empty?
    @annotation.reload
  end

  # Raises a 404 error when an annotation or master_file cannot be Found
  # @param [Symbol] The object that cannot be found (:annotation or :master_file)
  # @raise ActionController::RoutingError resolves as a 404 in browser
  def not_found(item: :annotation)
    raise ActionController::RoutingError.new(@not_found_messages[item])
  end
end
