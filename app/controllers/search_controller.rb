class SearchController < ApplicationController
  include Blacklight::Catalog

  def index
    puts "<< Searching ... >>"
    flash[:notice] = 'Doing the search thing'
    redirect_to catalog_index_path
  end
end
