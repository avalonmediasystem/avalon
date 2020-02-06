# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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
  if $('.migration_report').length > 0
    refresh = ->
      if $('#live-update').is(':checked')
        $.get document.location.href
        .done (data) ->
          $('.migration_report').html(data)
          setTimeout(refresh, 5000)
    setTimeout(refresh, 5000)
    $('#live-update').change -> refresh()
