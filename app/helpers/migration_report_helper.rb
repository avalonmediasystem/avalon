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

module MigrationReportHelper
  def status_link(klass, display_name, status_name=display_name)
    params = { class: klass, status: status_name }.reject { |k,v| v.nil? }
    params.delete(:status) if status_name == 'total'
    link_to @counts[klass][status_name].to_i, admin_migration_report_by_class_path(params)
  end

  def sort_params(col_name, default='id')
    new_params = params.reject { |k,v| k =~ /^(controller|action)$/ }
    (current_col,current_order) = new_params[:order].to_s.split
    current_col ||= default
    current_order ||= 'ASC'
    order = (current_col == col_name && current_order == 'ASC') ? 'DESC' : 'ASC'
    new_params[:order] = "#{col_name} #{order}"
    new_params.permit(:order, :class)
  end

  def status_string(status)
    status == "migrate" ? "In Progress" : status.titleize
  end
end
