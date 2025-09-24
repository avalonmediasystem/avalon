# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

class IiifCollectionManifestPresenter
  attr_reader :items, :params

  def initialize(items:, params:)
    @items = items.map { |item| IiifManifestPresenter.new(media_object: item, master_files: nil, lending_enabled: lending_enabled?(item)) }
    @params = params
  end

  def file_set_presenters
    []
  end

  def work_presenters
    items
  end

  def manifest_url
    Rails.application.routes.url_helpers.manifest_catalog_url(nil, *params.except(:action, :controller).permit!)
  end

  def to_s
    'Catalog Search'
  end

  def collection?
    true
  end

  def homepage
    [
      {
        id: Rails.application.routes.url_helpers.search_catalog_url(nil, *params.except(:action, :controller).permit!),
        type: "Text",
        label: { "none" => [I18n.t('iiif.manifest.homepageLabel')] },
        format: "text/html"
      }
    ]
  end

  def manifest_metadata
    @manifest_metadata ||= iiif_metadata_fields.compact
  end

  private

    def iiif_metadata_fields
      [
        "Title" => to_s
      ]
    end

    def lending_enabled?(context)
      return context&.cdl_enabled? if Avalon::Configuration.controlled_digital_lending_enabled?
      false
    end
end
