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

class EncodeRecordsController < ApplicationController
  before_action :set_encode_record, only: [:show]
  skip_before_action :verify_authenticity_token, only: [:progress]

  # GET /encode_records
  # GET /encode_records.json
  def index
    authorize! :read, :encode_dashboard
    @encode_records = ::ActiveEncode::EncodeRecord.all
  end

  # GET /encode_records/1
  # GET /encode_records/1.json
  def show
    authorize! :read, :encode_dashboard
  end

  # POST /encode_records/paged_index
  def paged_index
    authorize! :read, :encode_dashboard

    @encode_records = ::ActiveEncode::EncodeRecord.all
    records_total = ::ActiveEncode::EncodeRecord.count

    response = {
      "recordsTotal": records_total,
      "data": @encode_records.collect do |encode|
        encode_presenter = EncodePresenter.new(encode)
        encode_status = encode_presenter.status&.downcase
        unless encode_status == 'completed'
          progress_class = 'progress-bar-striped'
        end
        encode_progress = format_progress(encode_presenter)
        [
          "<span data-encode-id=\"#{encode.id}\" class=\"encode-status\">#{encode_presenter.status}</span>",
          view_context.link_to(encode_presenter.id, Rails.application.routes.url_helpers.encode_record_path(encode)),
          "<div class=\"progress progress-bar #{encode_status} #{progress_class}\" data-encode-id=\"#{encode.id}\" aria-valuenow=\"#{encode_progress}\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: #{encode_progress}%\"></div>",
          encode_presenter.display_title,
          view_context.link_to(encode_presenter.master_file_id, encode_presenter.master_file_url),
          view_context.link_to(encode_presenter.media_object_id, encode_presenter.media_object_url),
          encode_presenter.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    }
    respond_to do |format|
      format.json do
        render json: response
      end
    end
  end

  def progress
    authorize! :read, :encode_dashboard
    progress_data = {}
    ::ActiveEncode::EncodeRecord.where(id: params[:ids]).each do |encode|
      presenter = EncodePresenter.new(encode)
      progress_data[encode.id] = { progress: format_progress(presenter), status: presenter.status }
    end
    respond_to do |format|
      format.json do
        render json: progress_data
      end
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_encode_record
      @encode_record = ::ActiveEncode::EncodeRecord.find(params[:id])
    end

    def format_progress(presenter)
      # Set progress = 100.0 when job failed
      if presenter.status&.casecmp("failed") == 0
        100.0
      else
        presenter.progress
      end
    end
end
