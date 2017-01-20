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

class MigrationStatusController < ApplicationController
  
  before_filter :auth
  
  def index
    @migration_classes = ['Admin::Collection', 'Derivative', 'MasterFile', 'MediaObject', 'Lease']
    @counts = MigrationStatus.where(datastream: nil).group(:source_class, :status).count
  end
  
  def show
    criteria = { source_class: params[:class], datastream: nil }
    criteria[:status] = params[:status] == 'true' if ['true','false'].include?(params[:status])
    @statuses = MigrationStatus.where(criteria).order(params[:order] || :id).page(params[:page]).per(params[:per])
  end
  
  def detail
    @statuses = MigrationStatus.where(f3_pid: params[:id])
    @class = @statuses.first.source_class
    @f4_pid = @statuses.first.f4_pid
  end
  
  def report
    filename = "#{params[:id].sub(/:/,'_')}.json"
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
end
