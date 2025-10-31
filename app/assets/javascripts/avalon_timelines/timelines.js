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

this.add_copy_button_event = () => {
  queryAll('.copy-timeline-button').forEach(button => {
    button.addEventListener('click', function () {
      const timeline = JSON.parse(this.dataset.timeline);
      const modal = getById('copy-timeline-modal');

      if (!modal) return;

      const timelineName = query('#timeline-name', modal);
      if (timelineName) timelineName.value = timeline.title;

      const timelineComment = query('#timeline_comment', modal);
      if (timelineComment) timelineComment.value = timeline.comment;

      if (timeline.visibility === 'public') {
        const publicRadio = query('#timeline_visibility_public', modal);
        if (publicRadio) publicRadio.checked = true;
      } else if (timeline.visibility === 'private') {
        const privateRadio = query('#timeline_visibility_private', modal);
        if (privateRadio) privateRadio.checked = true;
      } else {
        const privateTokenRadio = query('#timeline_visibility_private-with-token', modal);
        if (privateTokenRadio) privateTokenRadio.checked = true;
      }

      const oldTimelineId = query('#old_timeline_id', modal);
      if (oldTimelineId) oldTimelineId.value = timeline.id;

      const token = query('#token', modal);
      if (token) token.value = timeline.access_token;

      const submitButton = query('#copy-timeline-submit', modal);
      if (submitButton) submitButton.disabled = false;

      const submitEditButton = query('#copy-timeline-submit-edit', modal);
      if (submitEditButton) submitEditButton.disabled = false;

      // toggle title error off
      const titleError = query('#title_error', modal);
      if (titleError) titleError.style.display = 'none';

      const modalInstance = bootstrap.Modal.getOrCreateInstance(modal);
      modalInstance.show();
    });
  });
};

const copyTimelineSubmitEdit = getById('copy-timeline-submit-edit');
if (copyTimelineSubmitEdit) {
  copyTimelineSubmitEdit.addEventListener('click', () => timeline_edit = true);
}

const timelineTitleInput = getById('timeline_title');
if (timelineTitleInput) {
  timelineTitleInput.addEventListener('keyup', function () {
    const modal = getById('copy-timeline-modal');
    if (!modal) return;

    const titleError = query('#title_error', modal);
    const submitButton = query('#copy-timeline-submit', modal);
    const submitEditButton = query('#copy-timeline-submit-edit', modal);

    if (this.value === '') {
      if (titleError) titleError.style.display = 'block';
      if (submitButton) submitButton.disabled = true;
      if (submitEditButton) submitEditButton.disabled = true;
    } else {
      if (titleError) titleError.style.display = 'none';
      if (submitButton) submitButton.disabled = false;
      if (submitEditButton) submitEditButton.disabled = false;
    }
  });
}

const copyTimelineForm = getById('copy-timeline-form');
if (copyTimelineForm) {
  copyTimelineForm.addEventListener('submit', function () {
    const modal = getById('copy-timeline-modal');
    if (!modal) return true;

    const timelineTitle = query('#timeline_title', modal);
    if (timelineTitle && timelineTitle.value) {
      const submitButton = query('#copy-timeline-submit', modal);
      if (submitButton) submitButton.disabled = true;
      return true;
    }
  });

  copyTimelineForm.addEventListener('ajax:success', function (event) {
    const [data, status, xhr] = Array.from(event.detail);
    if (data.errors) {
      console.log(data.errors.title[0]);
    } else {
      if (timeline_edit) {
        window.location.href = data.path;
      } else {
        const withRefresh = getById('with_refresh');
        if (withRefresh && withRefresh.value) {
          location.reload();
        }
      }
    }
  });

  copyTimelineForm.addEventListener('ajax:error', function (event) {
    const [data, status, xhr] = Array.from(event.detail);
    console.log(xhr.responseJSON.errors);
  });
}

queryAll('input[name="timeline[visibility]"]').forEach(input => {
  input.addEventListener('click', function () {
    const newVal = this.value;
    const helpTextElement = query('.human_friendly_visibility_' + newVal);
    const newText = helpTextElement ? helpTextElement.getAttribute('title') : '';
    const visibilityHelpText = query('.visibility-help-text');
    if (visibilityHelpText) {
      visibilityHelpText.textContent = newText;
    }

    const timelineLtiShare = getById('timeline_lti_share');
    if (timelineLtiShare) {
      if (newVal === 'private') {
        timelineLtiShare.style.display = 'none';
      } else {
        timelineLtiShare.style.display = 'block';
      }
    }
  });
});
