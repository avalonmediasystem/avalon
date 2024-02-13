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

module PlaylistsHelper
  def human_friendly_visibility(visibility)
    content_tag(:span,
      safe_join([icon_only_visibility(visibility),t("playlist.#{visibility}Text")], ' '),
      class: "human_friendly_visibility_#{visibility}",
      title: visibility_description(visibility))
  end

  def icon_only_visibility(visibility)
    icon = case visibility
      when Playlist::PUBLIC
        "fa-globe"
      when Playlist::PRIVATE
        "fa-lock"
      else
        "fa-link"
    end
    content_tag(:span, '', class:"fa #{icon} fa-lg", title: visibility_description(visibility))
  end

  def visibility_description(visibility)
    t("playlist.#{visibility}AltText")
  end
end
