class SearchController < ApplicationController
  include Blacklight::Catalog

  def index
    unless params[:q].nil? or params[:q].empty?
      puts "<< Searching for terms #{params[:q]} ... >>"
      
    else
      puts "<< Retrieving all results >>"
    end

    # TO DO : Grab all results for now and implement pagination with Solr and the
    #         Bootstrap gem(s) in a sprint post-R0 
    @results = Video.find(:all)   
  end
  
  def solr_search_params
    super.merge :per_page => 16
  end
end
