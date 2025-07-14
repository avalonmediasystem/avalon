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

$ ->
  $(document).on 'click', 'a[data-bs-trigger="submit"]', (event) ->
    $(this).closest('form').submit()

  initialized = false
  $('#browse-btn').browseEverything()
    .show ->
      unless $('#browse-everything input[name=workflow]').length > 0
        skip_box = $('#web_upload input[name=workflow]').closest('span')
          .clone().removeClass().css('margin-right','10px')
        $('.ev-cancel').before skip_box

      $('.ev-providers .ev-container a').click()
      initialized = true
    .done (data) ->
      if data.length > 0
        uploadModal = new bootstrap.Modal($('#uploading'))
        uploadModal.show()
        $('#dropbox_form input[name=workflow]').val($('#browse-everything input[name=workflow]:checked').val())
        $('#dropbox_form').submit()
