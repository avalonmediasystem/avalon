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


$('.typeahead.from-model').each ->
  $current_data = []
  $t = $(this)
  $target_id = $t.data('target')
  $target = $("input[name='#{$target_id}']")
  if $target_id
    $t.on 'change', ->
      if $target.val() == '' or $t.val() == ''
        $target.val($t.val())
  $t.attr('autocomplete','off')
  $t.typeahead
    minLength: 2
    source: (query, process) ->
      if $target_id
        $target.val('')
      $.get "#{$('body').data('mountpoint')}autocomplete",
        t: $t.data('model')
        q: query
        (data) ->
          $current_data = data
          display_values = $(data).map -> this.display
          process(display_values)
    updater: (item) ->
      if $target_id
        result = $.grep $current_data, (v) -> v.display == item
        result = if result.length > 0 then result[0].id else item
        $target.val(result)
      return item
