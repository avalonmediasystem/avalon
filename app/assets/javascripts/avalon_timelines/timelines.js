// Copyright 2011-2025, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.

// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.
// ---  END LICENSE_HEADER BLOCK  ---

let timeline_edit = null;

this.add_copy_button_event = () => $('.copy-timeline-button').on('click',
  function() {
    const timeline = $(this).data('timeline');
    const modal = $('#copy-timeline-modal');
    modal.find('#timeline-name').val(timeline.title);
    modal.find('#timeline_comment').val(timeline.comment);
    if (timeline.visibility === 'public') {
      modal.find('#timeline_visibility_public').prop('checked', true);
    } else if (timeline.visibility === 'private') {
      modal.find('#timeline_visibility_private').prop('checked', true);
    } else {
      modal.find('#timeline_visibility_private-with-token').prop('checked', true);
    }
    modal.find('#old_timeline_id').val(timeline.id);
    modal.find('#token').val(timeline.access_token);
    modal.find('#copy-timeline-submit').prop("disabled", false);
    modal.find('#copy-timeline-submit-edit').prop("disabled", false);

    // toggle title error off
    modal.find('#title_error').hide();

    return modal.modal('show');
  });

$('#copy-timeline-submit-edit').on('click',
  () => timeline_edit = true);

$('#timeline_title').on('keyup',
  function() {
    const modal = $('#copy-timeline-modal');
    if($(this).val() === '') {
      modal.find('#title_error').show();
      modal.find('#copy-timeline-submit').prop("disabled", true);
      return modal.find('#copy-timeline-submit-edit').prop("disabled", true);
    } else {
      modal.find('#title_error').hide();
      modal.find('#copy-timeline-submit').prop("disabled", false);
      return modal.find('#copy-timeline-submit-edit').prop("disabled", false);
    }
});

$('#copy-timeline-form').submit(
  function() {
    const modal = $('#copy-timeline-modal');
    if(modal.find('#timeline_title').val()) {
      modal.find('#copy-timeline-submit').prop("disabled", true);
      return true;
    }
});

$('#copy-timeline-form').bind('ajax:success',
  function(event) {
    const [data, status, xhr] = Array.from(event.detail);
    if (data.errors) {
      return console.log(data.errors.title[0]);
    } else {
      if (timeline_edit) {
        return window.location.href = data.path;
      } else {
        if ( $('#with_refresh').val() ) {
          return location.reload();
        }
      }
    }
}).bind('ajax:error',
  function(event) {
    const [data, status, xhr] = Array.from(event.detail);
    return console.log(xhr.responseJSON.errors);
});

$('input[name="timeline[visibility]"]').on('click', function() {
  const new_val = $(this).val();
  const new_text = $('.human_friendly_visibility_'+new_val).attr('title');
  $('.visibility-help-text').text(new_text);
  if (new_val === 'private') {
    return $('#timeline_lti_share').hide();
  } else {
    return $('#timeline_lti_share').show();
  }
});
