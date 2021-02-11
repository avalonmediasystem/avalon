/*
 * Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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
$('button[name="edit_label"]').on('click', e => {
  const $row = getHTMLInfo(e, '.row');
  const fileId = $row.data('file-id');
  const masterfileId = $row.data('masterfile-id');
  $row.find('small[name="flash-message-' + masterfileId + '-' + fileId + '"]').html('');
  $row.addClass('is-editing');
  $row.find('input[id="supplemental_file_input_' + masterfileId + '_'+ fileId +'"]').focus();
});

/* Hide form when form is cancelled */
$('button[name="cancel_edit_label"]').on('click', e => {
  const $row = getHTMLInfo(e, '.row');
  $row.removeClass('is-editing');
  });

/* After editing, close the form and show the new label */
$('button[name="save_label"]').on('click', e => {
  const $row = getHTMLInfo(e, '.row');
  const { fileId, masterfileId } = getHTMLInfo(e, 'form')[0].dataset;

  const newLabel = $row.find('input[id="supplemental_file_input_' + masterfileId + '_'+ fileId +'"]').val();
  // Set the label to the new value
  $row.find('span[name="label_' + masterfileId + '_' + fileId + '"]').text(newLabel);
  $row.removeClass('is-editing');
  // Remove feedback message after 5 seconds
  setTimeout( function() { 
    $row.find('small[name="flash-message-' + masterfileId + '-' + fileId + '"]').html('');
}, 5000);
});

/* Show feedback message inline after saving */
$('.supplemental-file-form').on("ajax:success", (event, data, status, xhr) => {
  $(event.currentTarget.parentElement).find('.visible-inline').html("Supplemental file successfully updated.")
}).on("ajax:error", (event, xhr, status, error) => {
  $(event.currentTarget.parentElement).find('.visible-inline').html("Failed to update.")
});

function getHTMLInfo(e, element) {
  return $(e.target).parents(element);
}