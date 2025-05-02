# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

class CollectionsController < CatalogController
  skip_before_action :enforce_show_permissions, only: :show

  def index
    response = blacklight_config.repository.search(CollectionSearchBuilder.new(self))
    collections = response.documents
    if (params[:only] == 'carousel')
      collections = collections.select { |doc| Settings.home_page&.carousel_collections&.include? doc.id }
    end
    if params[:limit].present?
      collections = collections.sample(params[:limit].to_i)
    end
    @doc_presenters = collections.collect { |doc| CollectionPresenter.new(doc, view_context) }

    respond_to do |format|
      format.html
      format.json { render json: @doc_presenters }
    end
  end

  def show
    response = blacklight_config.repository.search(CollectionSearchBuilder.new(self))
    document = response.documents.find { |doc| doc.id == params[:id] }
    # Only go on if params[:id] is in @response.documents
    raise CanCan::AccessDenied unless document
    @doc_presenter = CollectionPresenter.new(document, view_context)

    respond_to do |format|
      format.html
      format.json { render json: @doc_presenter }
    end
  end

  def poster
    response = blacklight_config.repository.search(CollectionSearchBuilder.new(self))
    document = response.documents.find { |doc| doc.id == params[:id] }
    # Only go on if params[:id] is in @response.documents
    raise CanCan::AccessDenied unless document

    @collection = SpeedyAF::Proxy::Admin::Collection.find(params['id'])

    file = @collection.poster
    if file.nil? || file.empty?
      render plain: 'Collection Poster Not Found', status: :not_found
    else
      render plain: file.content, content_type: file.mime_type
    end
  end
end
