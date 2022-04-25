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

# This script will enable support for the html5 form attribute
# This should only be needed for IE but is currently applied wholesale
# to all disjointed submit elements as is needed in some of the workflow steps

$ ->
  apply_button_confirmation()

@apply_button_confirmation = () ->
  $(document).on 'click', '#special_button_color', ->
    $('.btn-confirmation').popover 'hide'
    true
  $('.btn-confirmation').popover(
    trigger: 'manual'
    html: true
    sanitize: false
    content: ->
      button = undefined
      if typeof $(this).attr('form') == "undefined"
        button = '<a href="' + $(this).attr('href') + '" class="btn btn-sm btn-danger btn-confirm" data-method="delete" rel="nofollow">Yes, Delete</a>'
      else
        button = '<input class="btn btn-sm btn-danger btn-confirm" form="' + $(this).attr('form') + '" type="submit">'
        $('#' + $(this).attr('form')).find('[name=\'_method\']').val 'delete'
      '<p>Are you sure?</p> ' + button + ' <a href="#" class="btn btn-sm btn-primary" id="special_button_color">No, Cancel</a>'
  ).click ->
    $('.btn-confirmation').popover 'hide'
    $(this).popover 'show'
    false
