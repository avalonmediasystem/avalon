# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

class CollectionPresenter
  attr_reader :document, :view_context

  def initialize(solr_doc, view_context)
    @document = solr_doc
    @view_context = view_context
  end

  delegate :id, to: :document

  def name
    document["name_ssi"]
  end

  def unit
    document["unit_ssi"]
  end

  def description
    document["description_tesim"]&.first
  end

  def has_poster?
    document["has_poster_bsi"].present?
  end

  def poster_url
    return ActionController::Base.helpers.asset_url('collection_icon.png') unless has_poster?
    Rails.application.routes.url_helpers.poster_collection_url(id)
  end

  def collection_url
    Rails.application.routes.url_helpers.collection_url(id)
  end

  def contact_email
    document["contact_email_ssi"]
  end

  def website_link
    view_context.link_to document["website_label_ssi"], document["website_url_ssi"] unless document["website_url_ssi"].nil?
  end

  def as_json(_)
    {
      id: id,
      name: name,
      unit: unit,
      description: description,
      poster_url: poster_url,
      url: collection_url
    }
  end
end
