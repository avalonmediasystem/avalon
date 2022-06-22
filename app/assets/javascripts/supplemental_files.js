/* 
 * Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

/** Includes JS functions related to editing the supplemental file labels */

/* Show form to edit label */
$('button[name="edit_label"]').on('click', (e) => {
  const $row = getHTMLInfo(e, '.supplemental-file-data');
  const { masterfileId, fileId } = $row[0].dataset;

  $row.addClass('is-editing');
  $row
    .find(
      'input[id="supplemental_file_input_' + masterfileId + '_' + fileId + '"]'
    )
    .focus();
});

/* Hide form when form is cancelled */
$('button[name="cancel_edit_label"]').on('click', (e) => {
  const $row = getHTMLInfo(e, '.supplemental-file-data');
  $row.removeClass('is-editing');
});

/* After editing, close the form and show the new label */
$('button[name="save_label"]').on('click', (e) => {
  const $row = getHTMLInfo(e, '.supplemental-file-data');
  const { fileId, masterfileId } = getHTMLInfo(e, 'form')[0].dataset;

  $row.removeClass('is-editing');

  // Remove feedback message after 5 seconds
  setTimeout(function () {
    var alert = $row.find(
      'small[name="flash-message-' + masterfileId + '-' + fileId + '"]'
    );
    alert.html('');
    alert.removeClass();
    alert.addClass('visible-inline');
  }, 5000);
});

/* Show feedback message inline after saving */
$('.supplemental-file-form')
  .on('ajax:success', (event, data, status, xhr) => {
    var $row = $(event.currentTarget.parentElement);
    const { masterfileId, fileId } = event.currentTarget.dataset;

    // Set the label to the new value
    var newLabel = $row
      .find(
        'input[id="supplemental_file_input_' +
          masterfileId +
          '_' +
          fileId +
          '"]'
      )
      .val();
    $row
      .find('span[name="label_' + masterfileId + '_' + fileId + '"]')
      .text(newLabel);

    // Show flash message for success
    $row.find('.visible-inline').html('Successfully updated.');
    $row.find('.visible-inline').addClass('alert');
  })
  .on('ajax:error', (event, xhr, status, error) => {
    var alert = $(event.currentTarget.parentElement).find('.visible-inline');

    // Show flash warning for failed attempt
    alert.html('Failed to update.');
    alert.addClass('alert');
  });

/* Store collapsed section ids in localStorage */
$('button[id^=edit_section').on('click', (e) => {
  // Active sections
  var activeSections = JSON.parse(localStorage.getItem('activeSections')) || [];

  var currentSection = e.target.dataset['sectionId'];
  var isCollapsed = e.target.getAttribute('aria-expanded') == 'true';
  if (isCollapsed) {
    for (var i = 0; i < activeSections.length; i++) {
      if (activeSections[i] == currentSection) {
        activeSections.splice(i, 1);
      }
    }
  } else {
    activeSections.push(currentSection);
  }
  localStorage.setItem('activeSections', JSON.stringify(activeSections));
});

/* On page reload; collapse sections which were collapsed previously */
$(document).ready(function () {
  var activeSections = JSON.parse(localStorage.getItem('activeSections')) || [];

  // Collapse active sections on page
  activeSections.forEach((section) => {
    const sectionDiv = $('#collapseExample' + section);
    if (sectionDiv) {
      sectionDiv.collapse();
    }
  });
});

function getHTMLInfo(e, element) {
  return $(e.target).parents(element);
}
