module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def current_sort_field
    actualSort = @response.sort if (@response and @response.sort.present?)
    actualSort ||= params[:sort]
    blacklight_config.sort_fields[actualSort] || default_sort_field
  end

end
