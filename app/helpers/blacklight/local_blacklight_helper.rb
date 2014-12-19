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

end
