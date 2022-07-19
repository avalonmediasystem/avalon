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

@add_copy_button_event = () ->
  $('.copy-timeline-button').on('click',
    () ->
      timeline = $(this).data('timeline')
      modal = $('#copy-timeline-modal')
      modal.find('#timeline_title').val(timeline.title)
      modal.find('#timeline_comment').val(timeline.comment)
      if (timeline.visibility == 'public')
        modal.find('#timeline_visibility_public').prop('checked', true)
      else if (timeline.visibility == 'private')
        modal.find('#timeline_visibility_private').prop('checked', true)
      else
        modal.find('#timeline_visibility_private-with-token').prop('checked', true)
      modal.find('#old_timeline_id').val(timeline.id)
      modal.find('#token').val(timeline.access_token)
      modal.find('#copy-timeline-submit').prop("disabled", false)
      modal.find('#copy-timeline-submit-edit').prop("disabled", false)

      # toggle title error off
      modal.find('#title_error').hide()

      modal.modal('show')
    )

$('#copy-timeline-submit-edit').on('click',
  () ->
    submit_edit = true
)

$('#timeline_title').on('keyup',
  () ->
    modal = $('#copy-timeline-modal')
    if($(this).val() == '')
      modal.find('#title_error').show()
      modal.find('#copy-timeline-submit').prop("disabled", true)
      modal.find('#copy-timeline-submit-edit').prop("disabled", true)
    else
      modal.find('#title_error').hide()
      modal.find('#copy-timeline-submit').prop("disabled", false)
      modal.find('#copy-timeline-submit-edit').prop("disabled", false)
)

$('#copy-timeline-form').submit(
  () ->
    modal = $('#copy-timeline-modal')
    if(modal.find('#timeline_title').val())
      modal.find('#copy-timeline-submit').prop("disabled", true)
      return true
)

$('#copy-timeline-form').bind('ajax:success',
  (event, data, status, xhr) ->
    if (data.errors)
      console.log(data.errors.title[0])
    else
      if (submit_edit)
        window.location.href = data.path
      else
        if ( $('#with_refresh').val() )
          location.reload()
).bind('ajax:error',
  (e, xhr, status, error) ->
    console.log(xhr.responseJSON.errors)
)

$('input[name="timeline[visibility]"]').on('click', () ->
  new_val = $(this).val()
  new_text = $('.human_friendly_visibility_'+new_val).attr('title')
  $('.visibility-help-text').text(new_text)
  if (new_val == 'private')
    $('#timeline_lti_share').hide()
  else
    $('#timeline_lti_share').show()
)

# Hide instead of delete Bootstrap's dismissable alerts
$('.mejs-form-alert').on('close.bs.alert', (e) ->
  e.preventDefault()
  $(this).slideUp()
)
