# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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
    if (visibility == Playlist::PUBLIC)
      safe_join([icon_only_visibility(visibility),t("playlist.unlockText")], ' ')
    else
      safe_join([icon_only_visibility(visibility),t("playlist.lockText")], ' ')
    end
  end

  def icon_only_visibility(visibility)
    if (visibility == Playlist::PUBLIC)
      content_tag(:span, '', class:"fa fa-globe fa-lg", title: t("playlist.unlockAltText"))
    else
      content_tag(:span, '', class:"fa fa-lock fa-lg", title: t("playlist.lockAltText"))
    end
  end
end
