# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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
# frozen_string_literal: true
class CollectionsController < CatalogController
  skip_before_action :enforce_show_permissions, only: :show

  def index
    response = repository.search(CollectionSearchBuilder.new(self))
    @doc_presenters = response.documents.collect { |doc| CollectionPresenter.new(doc) }
  end

  def show
    response = repository.search(CollectionSearchBuilder.new(self))
    document = response.documents.find { |doc| doc.id == params[:id] }
    # Only go on if params[:id] is in @document_list
    raise CanCan::AccessDenied unless document
    @doc_presenter = CollectionPresenter.new(document)
  end
end
