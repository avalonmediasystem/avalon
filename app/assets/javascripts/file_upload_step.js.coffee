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

section_form = $('#associated_files form')
button_form = $('#workflow_buttons form')
$('input[type=text]',section_form).each () ->
  $(this).change () ->
    double_id = "#{$(this).attr('id')}_double'"
    double = $("input[id='#{double_id}']",button_form)
    unless double.length > 0
      double = $("<input type='hidden' id='#{double_id}' 
        name='#{$(this).attr('name')}' 
        value='#{$(this).val()}'/>").appendTo(button_form)
    double.val($(this).val())
$('input[type=submit]',section_form).hide()

$(document).on "click", ".btn-confirmation+.popover .btn", ->
  $('.btn-confirmation').popover('hide')
  return true

$('.btn-confirmation')
  .popover
    trigger: 'manual',
    html: true,
    content: () ->
      "<p>Are you sure?</p>
      <a href='#{$(this).attr('href')}' class='btn btn-xs btn-danger btn-confirm' data-method='delete' rel='nofollow'>Yes, Delete</a>
      <a href='#' class='btn btn-xs btn-primary btn-cancel'>No, Cancel</a>"
    placement: 'left'
  .click () -> 
    t = this
    $('.btn-confirmation')
      .filter(() -> this isnt t)
      .popover('hide')
    $(this).popover('show')
    return false
