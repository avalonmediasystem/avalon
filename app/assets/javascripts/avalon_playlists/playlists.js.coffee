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

submit_edit = null

@add_copy_playlist_button_event = () ->
  $('.copy-playlist-button').on('click',
    () ->
      playlist = $(this).data('playlist')
      modal = $('#copy-playlist-modal')
      modal.find('#playlist_title').val(playlist.title)
      modal.find('#playlist_comment').val(playlist.comment)
      if (playlist.visibility == 'public')
        modal.find('#playlist_visibility_public').prop('checked', true)
      else if (playlist.visibility == 'private')
        modal.find('#playlist_visibility_private').prop('checked', true)
      else
        modal.find('#playlist_visibility_private-with-token').prop('checked', true)
      modal.find('#old_playlist_id').val(playlist.id)
      modal.find('#token').val(playlist.access_token)
      modal.find('#copy-playlist-submit').prop("disabled", false)
      modal.find('#copy-playlist-submit-edit').prop("disabled", false)

      # toggle title error off
      modal.find('#title_error').hide()

      modal.modal('show')
    )

$('#copy-playlist-submit-edit').on('click',
  () ->
    submit_edit = true
)

$('#playlist_title').on('keyup',
  () ->
    modal = $('#copy-playlist-modal')
    if($(this).val() == '')
      modal.find('#title_error').show()
      modal.find('#copy-playlist-submit').prop("disabled", true)
      modal.find('#copy-playlist-submit-edit').prop("disabled", true)
    else
      modal.find('#title_error').hide()
      modal.find('#copy-playlist-submit').prop("disabled", false)
      modal.find('#copy-playlist-submit-edit').prop("disabled", false)
)

$('#copy-playlist-form').bind('ajax:success',
  (event) ->
    [data, status, xhr] = event.detail
    if (data.errors)
      console.log(data.errors.title[0])
    else
      if (submit_edit)
        window.location.href = data.path
      else
        if ( $('#with_refresh').val() )
          location.reload()
).bind('ajax:error',
  (event) ->
    [data, status, xhr] = event.detail
    console.log(xhr.responseJSON.errors)
)

$('input[name="playlist[visibility]"]').on('click', () ->
  new_val = $(this).val()
  new_text = $('.human_friendly_visibility_'+new_val).attr('title')
  $('.visibility-help-text').text(new_text)
)

# Hide instead of delete Bootstrap's dismissable alerts
$('.mejs-form-alert').on('close.bs.alert', (e) ->
  e.preventDefault()
  $(this).slideUp()
)
