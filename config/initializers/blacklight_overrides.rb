Blacklight::SolrResponse.class_eval do
  def sort
    params[:sort]
  end
end
