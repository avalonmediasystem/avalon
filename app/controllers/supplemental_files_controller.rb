# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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
  include Rails::Pagination

  before_action :set_object
  before_action :authorize_object

  rescue_from Avalon::SaveError do |exception|
    message = "An error occurred when saving the supplemental file: #{exception.message}"
    handle_error(message: message, status: 500)
  end

  rescue_from Avalon::BadRequest do |exception|
    handle_error(message: exception.full_message, status: 400)
  end

  rescue_from Avalon::NotFound do |exception|
    handle_error(message: exception.full_message, status: 404)
  end

  def index
    files = paginate SupplementalFile.where("parent_id = ?", @object.id)
    render json: files.to_a.collect { |f| f.as_json }
  end

  def create
    if metadata_upload? && !attachment
      raise Avalon::BadRequest, "Missing required Content-type headers" unless request.headers["Content-Type"] == 'application/json'
    end
    raise Avalon::BadRequest, "Missing required parameters" unless validate_params

    @supplemental_file = SupplementalFile.new(**metadata_from_params)
    
    if attachment
      begin
        @supplemental_file.attach_file(attachment)
      rescue StandardError, LoadError => e
        raise Avalon::SaveError, "File could not be attached: #{e.full_message}"
      end

      # Raise errror if file wasn't attached
      raise Avalon::SaveError, "File could not be attached." unless @supplemental_file.file.attached?
    end

    raise Avalon::SaveError, @supplemental_file.errors.full_messages unless @supplemental_file.save

    @object.supplemental_files += [@supplemental_file]
    raise Avalon::SaveError, @object.errors[:supplemental_files_json] unless @object.save

    flash[:success] = "Supplemental file successfully added."

    respond_to do |format|
      format.html {
        # This path is for uploading the binary file. We need to provide a JSON response
        # for the case of someone uploading through a CLI.
        if request.headers['Accept'] == 'application/json'
          render json: { id: @supplemental_file.id }, status: :created
        else
          redirect_to edit_structure_path
        end
      }
      # This path is for uploading the metadata payload.
      format.json { render json: { id: @supplemental_file.id }, status: :created }
    end
  end

  def show
    find_supplemental_file

    respond_to do |format|
      format.html { 
        # Redirect or proxy the content
        if Settings.supplemental_files.proxy
          send_data @supplemental_file.file.download, filename: @supplemental_file.file.filename.to_s, type: @supplemental_file.file.content_type, disposition: 'attachment'
        else
          redirect_to rails_blob_path(@supplemental_file.file, disposition: "attachment")
        end
      }
      format.json { render json: @supplemental_file.as_json }
    end
  end

  def update
    if metadata_upload?
      raise Avalon::BadRequest, "Incorrect request format. Use HTML if updating attached file." if attachment
      raise Avalon::BadRequest, "Missing required Content-type headers" unless request.headers["Content-Type"] == 'application/json'
    elsif request.headers['Avalon-Api-Key'].present?
      raise Avalon::BadRequest, "Incorrect request format. Use JSON if updating metadata." unless attachment
    end
    raise Avalon::BadRequest, "Missing required parameters" unless validate_params

    find_supplemental_file

    edit_file_information if !attachment

    @supplemental_file.attach_file(attachment) if attachment

    raise Avalon::SaveError, @supplemental_file.errors.full_messages unless @supplemental_file.save
    # Updates parent object's solr document
    @object.update_index

    flash[:success] = "Supplemental file successfully updated."
    respond_to do |format|
      format.html {
        # This path is for uploading the binary file. We need to provide a JSON response
        # for the case of someone uploading through a CLI.
        if request.headers['Accept'] == 'application/json'
          render json: { id: @supplemental_file.id }
        else
          redirect_to edit_structure_path
        end
      }
      # This path is for uploading the metadata payload.
      format.json { render json: { id: @supplemental_file.id }, status: :ok  }
    end
  end

  def destroy
    find_supplemental_file

    @object.supplemental_files -= [@supplemental_file]
    raise Avalon::SaveError, "An error occurred when deleting the supplemental file: #{@object.errors[:supplemental_files_json]}" unless @object.save
    # FIXME: also wrap this in a transaction
    raise Avalon::SaveError, "An error occurred when deleting the supplemental file: #{@supplemental_file.errors.full_messages}" unless @supplemental_file.destroy

    flash[:success] = "Supplemental file successfully deleted."
    respond_to do |format|
      format.html { redirect_to edit_structure_path }
      format.json { head :no_content }
    end
  end

  def captions
    find_supplemental_file

    file_content = @supplemental_file.file.download
    content = @supplemental_file.file.content_type == 'text/srt' ? SupplementalFile.convert_from_srt(file_content) : file_content

    send_data content, filename: @supplemental_file.file.filename.to_s, type: 'text/vtt', disposition: 'attachment'
  end

  private

    def set_object
      @object = fetch_object params[:master_file_id] || params[:media_object_id]
    end

    def validate_params
      attachment.present? || [:label, :language, :tags].any? { |v| supplemental_file_params[v].present? }
    end

    def supplemental_file_params
      # TODO: Add parameters for minio and s3
      sup_file_params = params.fetch(:supplemental_file, {}).permit(:label, :language, :file, tags: [])
      return sup_file_params unless metadata_upload?

      meta_params = params[:metadata].present? ? JSON.parse(params[:metadata]).symbolize_keys : params

      type = case meta_params[:type]
             when 'caption'
               'caption'
             when 'transcript'
               'transcript'
             else
               nil
             end
      treat_as_transcript = 'transcript' if meta_params[:treat_as_transcript] == true
      machine_generated = 'machine_generated' if meta_params[:machine_generated] == true

      sup_file_params[:label] ||= meta_params[:label].presence
      sup_file_params[:language] ||= meta_params[:language].presence
      # The uniq is to prevent multiple instances of 'transcript' tag if an update is performed with
      # `{ type: transcript, treat_as_transcript: 1}`
      sup_file_params[:tags] ||= [type, treat_as_transcript, machine_generated].compact.uniq
      sup_file_params
    end

    def find_supplemental_file
      # TODO: Use a master file presenter which reads from solr instead of loading the masterfile from fedora
      # FIXME: authorize supplemental file directly (needs supplemental file to have reference to masterfile)
      raise Avalon::NotFound, "Supplemental file: #{params[:id]} not found" unless SupplementalFile.exists? params[:id].to_s

      @supplemental_file = SupplementalFile.find(params[:id])
      raise Avalon::NotFound, "Supplemental file: #{@supplemental_file.id} not found" unless @object.supplemental_files.any? { |f| f.id == @supplemental_file.id }
    end


    def handle_error(message:, status:)
      if request.format == :json || request.headers['Avalon-Api-Key'].present?
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

    def edit_file_information
      update_tags

      @supplemental_file.label = supplemental_file_params[:label]
      return unless supplemental_file_params[:language].present?
      @supplemental_file.language = LanguageTerm.find(supplemental_file_params[:language]).code
    end

    def update_tags
      # The edit page only provides supplemental_file_params[:tags] on object creation.
      # Thus, we need to provide individual handling for both updates triggered by page
      # actions and updates through the JSON api.
      if request.format == 'json'
        @supplemental_file.tags = supplemental_file_params[:tags].presence
        return
      end

      file_params = [ 
        { param: "machine_generated_#{params[:id]}".to_sym, tag: "machine_generated", method: :machine_generated? },
        { param: "treat_as_transcript_#{params[:id]}".to_sym, tag: "transcript", method: :caption_transcript? }
      ]

      file_params.each do |v|
        param_name = v[:param]
        tag = v[:tag]
        method = v[:method]
        if params[param_name] && !@supplemental_file.send(method)
          @supplemental_file.tags += [tag]
        elsif !params[param_name] && @supplemental_file.send(method)
          @supplemental_file.tags -= [tag]
        end
      end
    end

    def metadata_from_params
      {
        label: supplemental_file_params[:label],
        tags: supplemental_file_params[:tags],
        language: supplemental_file_params[:language].present? ? LanguageTerm.find(supplemental_file_params[:language]).code : Settings.caption_default.language,
        parent_id: @object.id
      }.compact
    end

    def metadata_upload?
      params[:format] == 'json'
    end

    def attachment
      params[:file] || supplemental_file_params[:file]
    end

    def object_supplemental_file_path
      if @object.is_a? MasterFile
        master_file_supplemental_file_path(id: @supplemental_file.id, master_file_id: @object.id)
      else
        media_object_supplemental_file_path(id: @supplemental_file.id, media_object_id: @object.id)
      end
    end

    def authorize_object
      action = [:show, :captions].include?(action_name.to_sym) ? :show : :edit
      authorize! action, @object, message: "You do not have sufficient privileges to #{action_name} this supplemental file"
    end
end
