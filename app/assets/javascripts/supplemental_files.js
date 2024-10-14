/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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
  const { masterfileId, fileId, tag } = $row[0].dataset;

  if(tag == 'caption') { $('#edit-label-row').addClass('is-editing') };
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
  const { tag } = $row[0].dataset;

  $row.removeClass('is-editing');

  // Remove form label row
  if($('.captions').find('.is-editing').length === 1){
    $('#edit-label-row').removeClass('is-editing');
  }
});

/* After editing, close the form and show the new label */
$('button[name="save_label"]').on('click', (e) => {
  const $row = getHTMLInfo(e, '.supplemental-file-data');
  const { fileId, masterfileId } = getHTMLInfo(e, 'form')[0].dataset;

  $row.removeClass('is-editing');

  // Remove form label row
  if($('.captions').find('.is-editing').length === 1){
    $('#edit-label-row').removeClass('is-editing');
  }

  // Remove feedback message after 5 seconds
  setTimeout(function () {
    var alert = $row.find(
      'small[name="flash-message-' + masterfileId + '-' + fileId + '"]'
    );
    $row.find('.icon-success').addClass('d-none');
    $row.find('.icon-error').addClass('d-none');
    $row.find('.message-content').html();
    alert.removeClass();
    alert.addClass('visible-inline');
  }, 5000);
});

/* Show feedback message inline after saving */
$('.supplemental-file-form')
  .on('ajax:success', (event, data, status, xhr) => {
    var $row = $(event.currentTarget.parentElement);
    const { masterfileId, fileId } = event.currentTarget.dataset;
    // Get machine-generated checkbox input on form submission
    var isMachineGen = $row.find(`input[id="machine_generated_${fileId}"]`)[0].checked;

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
    $row.find('.message-content').html('Successfully updated.');
    // Show/hide icon based on the updated machine-generated form check
    isMachineGen
      ? $row.find('.fa-gears').removeClass('d-none')
      : $row.find('.fa-gears').addClass('d-none');
    $row.find('.icon-success').removeClass('d-none');
    $row.find('.visible-inline').addClass('alert');
  })
  .on('ajax:error', (event, xhr, status, error) => {
    var $row = $(event.currentTarget.parentElement)

    // Show flash warning for failed attempt
    $row.find('.message-content').html('Failed to update.');
    $row.find('.icon-error').removeClass('d-none');
    $row.find('.visible-inline').addClass('alert');
  });

/* Store collapsed section ids in localStorage if available */
$('button[id^=edit_section').on('click', (e) => {
  if (!Modernizr.localStorage) {
    return;
  }

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
  if (!Modernizr.localStorage) {
    return;
  }

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
