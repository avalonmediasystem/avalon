# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

module TimelinesHelper
  def timeline_human_friendly_visibility(visibility)
    content_tag(:span,
                safe_join([timeline_icon_only_visibility(visibility), t("timeline.#{visibility}Text")], ' '),
                class: "human_friendly_visibility_#{visibility}",
                title: timeline_visibility_description(visibility))
  end

  def timeline_icon_only_visibility(visibility)
    icon = case visibility
           when Timeline::PUBLIC
             "fa-globe"
           when Timeline::PRIVATE
             "fa-lock"
           else
             "fa-link"
           end
    content_tag(:span, '', class: "fa #{icon} fa-lg", title: timeline_visibility_description(visibility))
  end

  def timeline_visibility_description(visibility)
    t("timeline.#{visibility}AltText")
  end
end
