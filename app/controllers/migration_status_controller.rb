# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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
class MigrationStatusController < ApplicationController

  before_filter :auth
  layout 'migration_report'

  def index
    @counts = MigrationStatus.summary
    render without_layout_if_xhr
  end

  def show
    criteria = { source_class: params[:class], datastream: nil }
    if params[:status].present?
      criteria[:status] = "migrate" if params[:status] == "in progress"
      criteria[:status] ||= params[:status]
    end
    @statuses = MigrationStatus.where(criteria)
                  .order(sanitize_order(params[:order]) || :id)
                  .page(params[:page])
                  .per(params[:per])
    render without_layout_if_xhr
  end

  def detail
    @statuses = MigrationStatus.where(f3_pid: params[:id])
    @statuses = MigrationStatus.where(f4_pid: params[:id]) if @statuses.empty?
    raise ActiveRecord::RecordNotFound if @statuses.blank?
    @class = @statuses.first.source_class
    @f4_pid = @statuses.first.f4_pid
    if @f4_pid
      @f4_obj = ActiveFedora::Base.find(@f4_pid) rescue nil
    end
    @f3_pid = @statuses.first.f3_pid
    if @f3_pid
      @f3_obj = FedoraMigrate.source.connection.find(@f3_pid) rescue nil
    end
    render without_layout_if_xhr
  end

  def report
    filename = "#{params[:id].sub(/:/,'_')}.json"
    # Sanitize filename for security
    bar_chars = ['/', '\\']
    filename.gsub!(bar_chars,'_')
    send_file File.join(Rails.root, 'migration_report', filename), type: 'application/json', disposition: 'inline'
  end

  def auth
    if current_user.nil?
      flash[:notice] = "You need to login to view migration reports"
      redirect_to new_user_session_path
    elsif cannot? :read, MigrationStatus
      flash[:notice] = "You do not have permission to view migration reports"
      redirect_to root_path
    end
  end

  def without_layout_if_xhr
    request.xhr? ? { layout: false } : {}
  end

private

  # Avoid SQL injection attack on ActiveRecord order method
  # Input must be in format "column asc" or "column desc"
  def sanitize_order(order_param)
    if order_param.present?
      { order_param.split.first => order_param.split.second }
    else
      nil
    end
  end
end
