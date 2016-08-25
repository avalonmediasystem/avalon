# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
  def has_facet_values? fields = facet_field_names, options = {}
    facets_from_request(fields).any? { |display_facet| !display_facet.items.empty? && should_render_facet?(display_facet) }
  end

  def facet_field_names group=nil
    blacklight_config.facet_fields.select { |facet,opts| group == opts[:group] }.keys
  end

  def facet_group_names
    blacklight_config.facet_fields.map {|facet,opts| opts[:group]}.uniq
  end

  def url_for_document doc, options = {}
    media_object_path(doc[:id])
  end

  def contributor_index_display args
    args[:document][args[:field]].first(3).join("; ")
  end

  def description_index_display args
    field = args[:document][args[:field]]
    truncate(field, length: 200) unless field.blank?
  end

  def constraints_filters_string filters
    return if filters.nil?
    filters.map {|facet, values| contstraints_filter_string(facet, values)}.join(' / ')
  end

  def contstraints_filter_string(facet, values)
    facet_config = facet_configuration_for_field(facet)

    case values.size
    when 1
      "#{facet_field_label(facet_config.key)}: #{facet_display_value(facet, values.first)}"
    when 2 #if multiple facet selection enabled
      "#{facet_field_label(facet_config.key)}: #{facet_display_value(facet, values.first)} or #{facet_display_value(facet, values.last)}"
    else #if multiple facet selection enabled
      "#{facet_field_label(facet_config.key)}: #{values.size} selected"
    end
  end

  def constraints_string(localized_params = params)
    result = [localized_params[:q], constraints_filters_string(localized_params[:f])].keep_if(&:present?).join(" / ")
    result = t('blacklight.search.filters.none') if result.empty?
    result
  end

  def render_facet_count(num, options = {})
    classes = (options[:classes] || [])
    content_tag("div", :class => "facet-count") do
      content_tag("span", t('blacklight.search.facets.count', :number => number_with_delimiter(num)), :class => classes)
    end
  end

end
