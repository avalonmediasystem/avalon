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

$("input[type=submit]").on "click", (e) ->
  if $("#master_files_form").size() is 0
    $("#alerts").append "<div class=\"alert alert-danger\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><p>No files have been attached.</p></div>"
    false
  else
    true

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
      <a href='#' class='btn btn-xs btn-primary'  id='special_button_color'>No, Cancel</a>"
    placement: 'left'
  .click () -> 
    t = this
    $('.btn-confirmation')
      .filter(() -> this isnt t)
      .popover('hide')
    $(this).popover('show')
    return false
