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
  const sortableElement = query('.sortable');

  if (sortableElement) {
    // Find the media object form associated with the workflow button
    const mediaObjectForm = query('form[action*="media_objects"]');

    // Helper function to update master file IDs in the correct form
    function updateMasterFileIds() {
      if (!mediaObjectForm) return;

      // Remove existing hidden inputs from the media object form only
      const existingInputs = queryAll('[name="master_file_ids[]"]', mediaObjectForm);
      existingInputs.forEach(input => input.remove());

      // Add hidden inputs in new order
      const sections = queryAll('li.section', sortableElement);
      sections.forEach(function (section) {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = 'master_file_ids[]';
        input.value = section.getAttribute('data-segment');
        mediaObjectForm.appendChild(input);
      });
    }

    // Initialize master file IDs on page load
    updateMasterFileIds();

    // Initialize SortableJS on the sortable element
    Sortable.create(sortableElement, {
      handle: 'li.section',
      animation: 150,
      // Forces sortablejs to use its fallback mode, which gives 
      // us better control over the cursor style
      forceFallback: true,
      fallbackClass: 'sortable-fallback',
      onEnd: updateMasterFileIds,
    });
  }
});
