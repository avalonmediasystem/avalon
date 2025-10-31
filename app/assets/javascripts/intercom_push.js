/* 
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
*/

document.addEventListener('DOMContentLoaded', function () {
  const intercomPushModal = getById('intercom_push');
  if (intercomPushModal) {
    intercomPushModal.addEventListener('shown.bs.modal', function () {
      getIntercomCollections(false);
    });
  }
});
function getIntercomCollections(force, collections_path) {
  const select = getById('collection_id');
  if (!select) return;

  const options = queryAll('option', select);
  if (force || options.length === 0) {
    const submitButton = getById('intercom_push_submit_button');
    submitButton.disabled = true;

    // Remove all existing options
    select.innerHTML = '';

    // Add loading option
    const loadingOption = document.createElement('option');
    loadingOption.value = '';
    loadingOption.disabled = true;
    loadingOption.selected = true;
    loadingOption.textContent = 'Fetching Collections from Target...';
    select.appendChild(loadingOption);

    // Make AJAX request
    fetch(`${collections_path}?reload=${force ? 'true' : 'false'}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then(response => response.json())
      .then(result => {
        // Remove all options and add new options from response
        select.innerHTML = '';
        result.forEach((c) => {
          const option = document.createElement('option');
          option.value = c['id'];
          option.textContent = c['name'];
          if (c['default']) option.selected = true;
          select.appendChild(option);
        });
        submitButton.disabled = false;
      })
      .catch(() => {
        const firstOption = query('option', select);
        if (firstOption) {
          firstOption.textContent = 'There was an error communicating with the target.';
        }
      });
  }
}
