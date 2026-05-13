# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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
class IndexHeaderMediaObjectComponent < Blacklight::DocumentTitleComponent
  include TimeFormattingHelper

  def initialize(**kwargs)
    super
    @classes += @actions.present? ? " col-sm-9 col-lg-10" : " col-md-12"
    @title = search_result_label(presenter.document)
  end

  # Override to add test-id
  def title
    if @link_to_document
      helpers.link_to_document presenter.document, @title.presence || content.presence, counter: @counter, itemprop: 'name', data: { testid: "browse-document-title-#{presenter.document.id}" }
    else
      content_tag('span', @title.presence || content.presence || presenter.heading, itemprop: 'name')
    end
  end

  private

  def search_result_label document
    if document['title_tesi'].present?
      label = truncate(document['title_tesi'], length: 100)
    else
      label = document[:id]
    end

    if document['duration_ssi'].present?
      duration = document['duration_ssi']
      if duration.respond_to?(:to_i) && duration.to_i > 0
        label += " (#{milliseconds_to_formatted_time(duration.to_i, false)})"
      end
    end

    label
  end
end
