# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

submit_edit = null

@add_copy_button_event = () ->
  $('.copy-playlist-button').on('click',
    () ->
      playlist = $(this).data('playlist')
      $('#playlist_title').val(playlist.title)
      $('#playlist_comment').val(playlist.comment)
      if (playlist.visibility == 'public')
        $('#playlist_visibility_private').prop('checked', false)
        $('#playlist_visibility_public').prop('checked', true)
      else
        $('#playlist_visibility_private').prop('checked', true)
        $('#playlist_visibility_public').prop('checked', false)
      $('#old_playlist_id').val(playlist.id)
      $('#copy-playlist-submit').prop("disabled", false)
      $('#copy-playlist-submit-edit').prop("disabled", false)
      $('#copy-playlist').modal('show')
    )

$('#copy-playlist-submit-edit').on('click',
  () ->
    submit_edit = true
)

$('#copy-playlist-form').submit(
  () ->
    disable_submit()
    return true
)

disable_submit = () ->
  $('#copy-playlist-submit').prop("disabled", true)
  $('#copy-playlist-submit-edit').prop("disabled", true)

$('#copy-playlist-form').bind('ajax:success',
  (event, data, status, xhr) ->
    if (data.errors)
      console.log(data.errors.title[0])
    else
      if (submit_edit)
        window.location.href = data.path
      else
        location.reload()
)
