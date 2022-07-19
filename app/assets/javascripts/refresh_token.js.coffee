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

$ ->
  refreshToken = ->
    if currentPlayer != undefined
      token = currentPlayer.media.src.split('?')[1]
      if token && token.match(/^token=/)
        mount_point = $('body').data('mountpoint')
        $.get("#{mount_point}authorize.txt?#{token}")
          .done -> console.log("Token refreshed")
          .fail -> console.error("Token refresh failed")

  setInterval(refreshToken, 5*60*1000)
