# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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

module Blacklight::LocalBlacklightHelper 
  def facet_field_names group=nil
    blacklight_config.facet_fields.select { |facet,opts|
      ability = opts[:if_user_can]
      group == opts[:group] && (ability.nil? || can?(*ability))
    }.keys
  end

  # There might be a better way to do this but the goal is to retrieve the
  # name of the first facet group. This will be used as the link so that
  # when the page goes responsive it collapses _all_ groups into a single
  # dropdown to save screen real estate
  def facet_header 
    t('blacklight.search.facets.title')
  end

  def facet_group_names
    blacklight_config.facet_fields.map {|facet,opts| opts[:group]}.uniq
  end

  def render_index_doc_actions(document, options={})   
    wrapping_class = options.delete(:wrapping_class) || "documentFunctions" 

    content = []
    content_tag("div", content.join("\n").html_safe, :class=> wrapping_class)
  end

  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display. 
  def render_facet_count(num)
    content_tag("span", t('blacklight.search.facets.count', :number => num), :class => "badge") 
  end

  #Why are we overriding link_to_document?
  def link_to_document(doc, opts={:label=>nil, :counter => nil, :results_view => true})
    opts[:label] ||= blacklight_config.index.show_link.to_sym
    label = render_document_index_label doc, opts
    name = document_partial_name(doc)
    url = name.pluralize + "/" + doc["id"]
    link_to label, url, { :'data-counter' => opts[:counter] }.merge(opts.reject { |k,v| [:label, :counter, :results_view].include? k })
  end

  def contributor_index_display args
    args[:document][args[:field]].first(3).join("; ")
  end

  def description_index_display args
    field = args[:document][args[:field]]
    truncate(field, length: 200) unless field.blank?
  end

  # Determine whether to expand the facet or not based on the settings in
  # the catalog controller and the (lack of) presence in the params hash
  #
  # This is a new method that doesn't currently exist in the Blacklight
  # module
  def expand_facet? facet
    expand = facet.expanded || false
    # If the controller doesn't not expand it by default we need to do some
    # extra work and check the params hash
    if params[:f].present?
      expand = expand || params[:f][facet.field].present?
    end

    expand
  end
end
