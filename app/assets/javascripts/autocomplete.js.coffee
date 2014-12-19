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

@initialize_typeahead = ($t) ->
  $target = $t.parent().find("input[name='#{$t.data('target')}']")
  $validate = $t.data('validate') || false
  $t.attr('autocomplete','off')
  mySource = new Bloodhound(
    limit: 10
    datumTokenizer: (d) ->
      Bloodhound.tokenizers.whitespace(d.display)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    prefetch: "#{$('body').data('mountpoint')}autocomplete?q=&t=#{$t.data('model')}"
  )
  mySource.initialize()
  $t.typeahead(
    minLength: 2
  ,
    displayKey: (suggestion) ->
      if suggestion.display is ""
        suggestion.id
      else
        suggestion.display
    source: mySource.ttAdapter()
    templates:
      suggestion: (suggestion) ->
        "<p>" + suggestion.display + "</p>"
  ).on("typeahead:selected typeahead:autocompleted", (event, suggestion, dataset) ->
    $target.val suggestion["id"]
    return
  ).on("keypress", (e) ->
    if e.which is 13
      e.preventDefault
      return false
  ).blur ->
    if !$validate or $(this).val() is ""
      $target.val $(this).val()
      return
    match = false
    i = mySource.index.datums.length - 1
    while i >= 0
      if $(this).val() is mySource.index.datums[i].display
        match = true
        $target.val mySource.index.datums[i].id
        i=0
      i--
    if !match
      $target.val ""
      $(this).val ""
    return

$('.typeahead.from-model').each ->
  initialize_typeahead ($(this))
  return