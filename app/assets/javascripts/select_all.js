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

$("#bookmarks_selectall").on("click", function (e) {
  // Disable 'Select All' to prevent collision between select
  // and deselect POST requests while the page is getting updated
  $(this).prop("disabled", true);
  if (!$(this).is(':checked')) {
    $("label.toggle-bookmark.checked input.toggle-bookmark").each(function (index, input) {
      input.click();
    });
  } else {
    $("label.toggle-bookmark:not(.checked) input.toggle-bookmark").each(function (index, input) {
      input.click();
    });
  }
  // Enable 'Select All' afer
  $(this).prop("disabled", false);
  return;
});

// Fetch total bookmarks count after all POST requests for each document 
// finishes. And update 'Selected Items' count in the nav bar
$(document).ajaxStop(function () {
  fetch('/bookmarks/count.json')
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      $("span[data-role='bookmark-counter']").text(data['count']);
      $('#bookmarks_selectall')[0].prop("disabled", false);
    });
});

