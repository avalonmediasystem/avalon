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
  $(document).on 'click', 'a[data-trigger="submit"]', (event) ->
    $(this).closest('form').submit()

  initialized = false
  $('#browse-btn').browseEverything()
    .show ->
      alertMsg = $('<div>')
        .html('Warning! Uploading too many files at once can lead to ingest failures.')
        .addClass('alert')
        .addClass('alert-danger')
        .css('margin','3px')
        .css('text-align','center')
      $('.ev-body').prepend(alertMsg)
      unless $('#browse-everything input[name=workflow]').length > 0
        skip_box = $('#web_upload input[name=workflow]').closest('span')
          .clone().removeClass().css('margin-right','10px')
        $('.ev-cancel').before skip_box

      $('.ev-providers .ev-container a').click()
      initialized = true
    .done (data) ->
      if data.length > 0
        $('#uploading').modal('show')
        $('#dropbox_form input[name=workflow]').val($('#browse-everything input[name=workflow]:checked').val())
        $('#dropbox_form').submit()
