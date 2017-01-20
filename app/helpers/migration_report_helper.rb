module MigrationReportHelper
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
