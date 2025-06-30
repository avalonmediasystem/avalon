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

// Global abort controller for managing select all operations
let selectAllAbortController = null;
let isSelectAllInProgress = false;

function processCheckboxes(checkboxes, selectAllCheckbox) {
  // If there are no checkboxes to process, re-enable immediately
  if (checkboxes.length === 0) {
    selectAllCheckbox.prop("disabled", false);
    isSelectAllInProgress = false;
  }

  let completedCount = 0;
  checkboxes.each(function (index, input) {
    // Check if select all operation was aborted before starting each operation
    if (selectAllAbortController.signal.aborted) {
      return false;
    }

    // Use a timeout for better handling of async operations
    setTimeout(() => {
      if (!selectAllAbortController.signal.aborted) {
        input.click();
        completedCount++;
        // Re-enable select all when all operations complete
        if (completedCount === checkboxes.length) {
          selectAllCheckbox.prop("disabled", false);
          isSelectAllInProgress = false;
        }
      }
    }, index * 100);
  });
}

$("#bookmarks_selectall").on("click", function (e) {
  // If a select all operation is already in progress, abort it and start a new one
  if (isSelectAllInProgress && selectAllAbortController) {
    selectAllAbortController.abort();
  }
  selectAllAbortController = new AbortController();
  isSelectAllInProgress = true;

  // Disable 'Select All' to prevent collision between select
  // and deselect POST requests while the page is getting updated
  $(this).prop("disabled", true);

  // Check if operation was aborted before starting
  if (selectAllAbortController.signal.aborted) {
    $(this).prop("disabled", false);
    isSelectAllInProgress = false;
    return;
  }

  if (!$(this).is(':checked')) {
    const checkedCheckboxes = $("label.toggle-bookmark input.toggle-bookmark:checked");
    processCheckboxes(checkedCheckboxes, $(this));
  } else {
    const uncheckedCheckboxes = $("label.toggle-bookmark input.toggle-bookmark:not(:checked)");
    processCheckboxes(uncheckedCheckboxes, $(this));
  }
});

// Clean up abort controller when page unloads
$(window).on('beforeunload', function () {
  if (selectAllAbortController) {
    selectAllAbortController.abort();
  }
});
