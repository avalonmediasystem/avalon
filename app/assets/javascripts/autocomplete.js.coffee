# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
  # Get the closest 'Add' button related to the input text field
  add_button = ($t.closest 'div').next().first().children()
  # Disable the 'Add' button
  add_button.prop 'disabled', true
  mySource = new Bloodhound(
    datumTokenizer: Bloodhound.tokenizers.whitespace('display')
    queryTokenizer: Bloodhound.tokenizers.whitespace
    remote:
      url: "#{$('body').data('mountpoint')}autocomplete?q=%QUERY&t=#{$t.data('model')}&id=#{$t.data('media-object-id')}"
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
    target.val suggestion["id"] || suggestion["display"]
    $t.data('matched_val',suggestion["display"])
    # Enable 'Add' button when input is completed
    add_button.prop 'disabled', false
    return
  ).on("keydown", (e) ->
    # Disable 'Add' button when selected value is partially cleared
    # by pressing 'Backspace' key
    if e.which is 8
      add_button.prop 'disabled', true
  ).on("keypress", (e) ->
    if e.which is 13
      e.preventDefault
      return false
  ).on("input", (e) ->
    # Disable 'Add' button when input field is fully cleared without using backspace
    # Example: Ctrl + X
    if $(this).val().trim() is ''
      add_button.prop 'disabled', true
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
