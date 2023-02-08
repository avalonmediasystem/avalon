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

    # Encode records for index page are loaded dynamically by jquery datatables javascript which
    # requests the html for only a limited set of rows at a time.
    columns = %w[state id progress display_title master_file_id media_object_id created_at].freeze

    records_total = ::ActiveEncode::EncodeRecord.count

    # Filter
    search_value = params['search']['value']
    @encode_records = if search_value.present?
                        ::ActiveEncode::EncodeRecord.where %(
                          state LIKE :search_value OR
                          CAST(id as char) LIKE :search_value OR
                          CAST(progress as char) LIKE :search_value OR
                          display_title LIKE :search_value OR
                          master_file_id LIKE :search_value OR
                          media_object_id LIKE :search_value OR
                          CAST(created_at as char(19)) LIKE :search_value
                        ), search_value: "%#{search_value}%"
                      else
                        ::ActiveEncode::EncodeRecord.all
                      end
    filtered_records_total = @encode_records.count

    # Sort
    sort_column = columns[params['order']['0']['column'].to_i]
    sort_direction = params['order']['0']['dir'] == 'desc' ? 'desc' : 'asc'
    @encode_records = @encode_records.order(Arel.sql("lower(CAST(#{sort_column} as char)) #{sort_direction}, #{sort_column} #{sort_direction}"))

    # Paginate
    page_num = (params['start'].to_i / params['length'].to_i).floor + 1
    @encode_records = @encode_records.page(page_num).per(params['length'])

    response = {
      "draw": params['draw'],
      "recordsTotal": records_total,
      "recordsFiltered": filtered_records_total,
      "data": @encode_records.collect do |encode|
        encode_presenter = EncodePresenter.new(encode)
        encode_status = encode_presenter.status.downcase
        unless encode_status == 'completed'
          progress_class = 'progress-bar-striped'
        end
        encode_progress = format_progress(encode_presenter)
        [
          "<span data-encode-id=\"#{encode.id}\" class=\"encode-status\">#{encode_presenter.status}</span>",
          view_context.link_to(encode_presenter.id, Rails.application.routes.url_helpers.encode_record_path(encode)),
          "<div class=\"progress\"><div class=\"progress-bar #{encode_status} #{progress_class}\" data-encode-id=\"#{encode.id}\" aria-valuenow=\"#{encode_progress}\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: #{encode_progress}%\"></div></div>",
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
      if presenter.status.casecmp("failed") == 0
        100.0
      else
        presenter.progress
      end
    end
end
