# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

@initialize_typeahead = ($t) ->
  $validate = $t.data('validate') || false
  $t.attr('autocomplete','off')
  mySource = new Bloodhound(
    datumTokenizer: Bloodhound.tokenizers.whitespace('display')
    queryTokenizer: Bloodhound.tokenizers.whitespace
    remote:
      url: "#{$('body').data('mountpoint')}autocomplete?q=%QUERY&t=#{$t.data('model')}"
      wildcard: '%QUERY'
  )
  mySource.initialize()
  $t.typeahead(
    minLength: 2
    highlight: true
  ,
    display: (suggestion) ->
      if suggestion.display is ""
        suggestion.id
      else
        suggestion.display
    source: mySource
    limit: 10
  ).on("typeahead:selected typeahead:autocompleted", (event, suggestion, dataset) ->
    target = $("##{$t.data('target')}")
    target.val suggestion["id"]
    $t.data('matched_val',suggestion["display"])
    return
  ).on("keypress", (e) ->
    if e.which is 13
      e.preventDefault
      return false
  ).blur ->
    target = $("##{$t.data('target')}")
    typed = $(this).val()
    if typed is ""
      target.val ""
    else if $t.data('matched_val') != typed
      mySource.remote.get typed, (matches) ->
        if !$validate
          target.val typed
        else if matches.length > 0
          target.val matches[0].id
        else
          target.val ""
          $(this).val ""
      return

$('.typeahead.from-model').each ->
  initialize_typeahead ($(this))
  return
