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

# frozen_string_literal: true
class SupplementalFilesController < ApplicationController
  before_action :set_object
  before_action :authorize_object

  rescue_from Avalon::SaveError do |exception|
    message = "An error occurred when saving the supplemental file: #{exception.full_message}"
    handle_error(message: message, status: 500)
  end

  rescue_from Avalon::BadRequest do |exception|
    handle_error(message: exception.full_message, status: 400)
  end

  rescue_from Avalon::NotFound do |exception|
    handle_error(message: exception.full_message, status: 404)
  end

  def create
    # FIXME: move filedata to permanent location
    raise Avalon::BadRequest, "Missing required parameters" unless supplemental_file_params[:file]

    @supplemental_file = SupplementalFile.new(label: supplemental_file_params[:label], tags: supplemental_file_params[:tags])
    begin
      @supplemental_file.attach_file(supplemental_file_params[:file])
    rescue StandardError, LoadError => e
      raise Avalon::SaveError, "File could not be attached: #{e.full_message}"
    end

    # Raise errror if file wasn't attached
    raise Avalon::SaveError, "File could not be attached." unless @supplemental_file.file.attached?

    raise Avalon::SaveError, @supplemental_files.errors.full_messages unless @supplemental_file.save

    @object.supplemental_files += [@supplemental_file]
    raise Avalon::SaveError, @object.errors[:supplemental_files_json].full_messages unless @object.save

    flash[:success] = "Supplemental file successfully added."

    respond_to do |format|
      format.html { redirect_to edit_structure_path }
      format.json { head :created, location: object_supplemental_file_path }
    end
  end

  def show
    # TODO: Use a master file presenter which reads from solr instead of loading the masterfile from fedora
    # FIXME: authorize supplemental file directly (needs supplemental file to have reference to masterfile)
    raise Avalon::NotFound, "Supplemental file: #{params[:id]} not found" unless SupplementalFile.exists? params[:id].to_s

    @supplemental_file = SupplementalFile.find(params[:id])
    raise Avalon::NotFound, "Supplemental file: #{@supplemental_file.id} not found" unless @object.supplemental_files.any? { |f| f.id == @supplemental_file.id }

    # Redirect or proxy the content
    if Settings.supplemental_files.proxy
      send_data @supplemental_file.file.download, filename: @supplemental_file.file.filename.to_s, type: @supplemental_file.file.content_type, disposition: 'attachment'
    else
      redirect_to rails_blob_path(@supplemental_file.file, disposition: "attachment")
    end
  end

  # Update the label of the supplemental file
  def update
    raise Avalon::NotFound, "Cannot update the supplemental file: #{params[:id]} not found" unless SupplementalFile.exists? params[:id].to_s
    @supplemental_file = SupplementalFile.find(params[:id])
    raise Avalon::NotFound, "Cannot update the supplemental file: #{@supplemental_file.id} not found" unless @object.supplemental_files.any? { |f| f.id == @supplemental_file.id }
    raise Avalon::BadRequest, "Updating file contents not allowed" if supplemental_file_params[:file].present?

    @supplemental_file.label = supplemental_file_params[:label]
    raise Avalon::SaveError, @supplemental_file.errors.full_messages unless @supplemental_file.save

    flash[:success] = "Supplemental file successfully updated."
    respond_to do |format|
      format.html { redirect_to edit_structure_path }
      format.json { head :ok, location: object_supplemental_file_path }
    end
  end

  def destroy
    raise Avalon::NotFound, "Cannot delete the supplemental file: #{params[:id]} not found" unless SupplementalFile.exists? params[:id].to_s
    @supplemental_file = SupplementalFile.find(params[:id])
    raise Avalon::NotFound, "Cannot delete the supplemental file: #{@supplemental_file.id} not found" unless @object.supplemental_files.any? { |f| f.id == @supplemental_file.id }

    @object.supplemental_files -= [@supplemental_file]
    raise Avalon::SaveError, "An error occurred when deleting the supplemental file: #{@object.errors[:supplemental_files_json].full_messages}" unless @object.save
    # FIXME: also wrap this in a transaction
    raise Avalon::SaveError, "An error occurred when deleting the supplemental file: #{@supplemental_file.errors.full_messages}" unless @supplemental_file.destroy

    flash[:success] = "Supplemental file successfully deleted."
    respond_to do |format|
      format.html { redirect_to edit_structure_path }
      format.json { head :no_content }
    end
  end

  private

    def set_object
      @object = fetch_object params[:master_file_id] || params[:media_object_id]
    end

    def supplemental_file_params
      # TODO: Add parameters for minio and s3
      params.fetch(:supplemental_file, {}).permit(:label, :file, tags: [])
    end

    def handle_error(message:, status:)
      if request.format == :json
        render json: { errors: message }, status: status
      else
        flash[:error] = message
        redirect_to edit_structure_path
      end
    end

    def edit_structure_path
      media_object_id = if @object.is_a? MasterFile
                          @object.media_object_id
                        else
                          @object.id
                        end
      edit_media_object_path(media_object_id, step: 'file-upload')
    end

    def object_supplemental_file_path
      if @object.is_a? MasterFile
        master_file_supplemental_file_path(id: @supplemental_file.id, master_file_id: @object.id)
      else
        media_object_supplemental_file_path(id: @supplemental_file.id, media_object_id: @object.id)
      end
    end

    def authorize_object
      authorize! action_name.to_sym, @object, message: "You do not have sufficient privileges to #{action_name} this supplemental file"
    end
end
