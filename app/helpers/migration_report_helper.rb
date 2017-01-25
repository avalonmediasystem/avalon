module MigrationReportHelper
  def status_link(klass, display_name, status_name=display_name)
    params = { class: klass, status: status_name }.reject { |k,v| v.nil? }
    link_to @counts[klass][status_name].to_i, admin_migration_report_by_class_path(params)
  end
  
  def sort_params(col_name, default='id')
    new_params = params.reject { |k,v| k =~ /^(controller|action)$/ }
    (current_col,current_order) = new_params[:order].to_s.split
    current_col ||= default
    current_order ||= 'ASC'
    order = (current_col == col_name && current_order == 'ASC') ? 'DESC' : 'ASC'
    new_params[:order] = "#{col_name} #{order}"
    new_params
  end
end
