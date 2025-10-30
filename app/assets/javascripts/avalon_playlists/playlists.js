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

let playlist_edit = null;

this.add_copy_playlist_button_event = () => {
  queryAll('.copy-playlist-button').forEach(button => {
    button.addEventListener('click', function () {
      const playlist = JSON.parse(this.dataset.playlist);
      const modal = getById('copy-playlist-modal');

      if (!modal) return;

      console.log(playlist);
      const playlistTitle = getById('playlist_title');
      if (playlistTitle) playlistTitle.value = playlist.title;

      const playlistComment = getById('playlist_comment');
      if (playlistComment) playlistComment.value = playlist.comment;

      if (playlist.visibility === 'public') {
        const publicRadio = getById('playlist_visibility_public');
        if (publicRadio) publicRadio.checked = true;
      } else if (playlist.visibility === 'private') {
        const privateRadio = getById('playlist_visibility_private');
        if (privateRadio) privateRadio.checked = true;
      } else {
        const privateTokenRadio = getById('playlist_visibility_private-with-token', modal);
        if (privateTokenRadio) privateTokenRadio.checked = true;
      }

      const oldPlaylistId = getById('old_playlist_id');
      if (oldPlaylistId) oldPlaylistId.value = playlist.id;

      const token = getById('token', modal);
      if (token) token.value = playlist.access_token;

      const submitButton = getById('copy-playlist-submit');
      if (submitButton) submitButton.disabled = false;

      const submitEditButton = getById('copy-playlist-submit-edit');
      if (submitEditButton) submitEditButton.disabled = false;

      // toggle title error off
      const titleError = getById('title_error');
      if (titleError) titleError.style.display = 'none';

      const modalInstance = bootstrap.Modal.getOrCreateInstance(modal);
      modalInstance.show();
    });
  });
};

const copyPlaylistSubmitEdit = getById('copy-playlist-submit-edit');
if (copyPlaylistSubmitEdit) {
  copyPlaylistSubmitEdit.addEventListener('click', () => playlist_edit = true);
}

const playlistTitleInput = getById('playlist_title');
if (playlistTitleInput) {
  playlistTitleInput.addEventListener('keyup', function () {
    const modal = getById('copy-playlist-modal');
    if (!modal) return;

    const titleError = getById('title_error');
    const submitButton = getById('copy-playlist-submit');
    const submitEditButton = getById('copy-playlist-submit-edit');

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

const copyPlaylistForm = getById('copy-playlist-form');
if (copyPlaylistForm) {
  copyPlaylistForm.addEventListener('ajax:success', function (event) {
    const [data, status, xhr] = Array.from(event.detail);
    if (data.errors) {
      console.log(data.errors.title[0]);
    } else {
      if (playlist_edit) {
        window.location.href = data.path;
      } else {
        const withRefresh = getById('with_refresh');
        if (withRefresh && withRefresh.value) {
          location.reload();
        }
      }
    }
  });

  copyPlaylistForm.addEventListener('ajax:error', function (event) {
    const [data, status, xhr] = Array.from(event.detail);
    console.log(xhr.responseJSON.errors);
  });
}

queryAll('input[name="playlist[visibility]"]').forEach(input => {
  input.addEventListener('click', function () {
    const newVal = this.value;
    const helpTextElement = query('.human_friendly_visibility_' + newVal);
    const newText = helpTextElement ? helpTextElement.getAttribute('title') : '';
    const visibilityHelpText = query('.visibility-help-text');
    if (visibilityHelpText) {
      visibilityHelpText.textContent = newText;
    }
  });
});
