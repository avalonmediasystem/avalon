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

/** Includes JS functions related to editing the supplemental file labels */

/* Show form to edit label */
queryAll('button[name="edit_label"]').forEach(button => {
  button.addEventListener('click', (e) => {
    const row = getHTMLInfo(e, '.supplemental-file-data');
    const { masterfileId, fileId, tag } = row.dataset;

    if (tag === 'caption') {
      const editLabelRow = getById('edit-label-row');
      editLabelRow.classList.add('is-editing');
    }
    row.classList.add('is-editing');
    const input = query(`input[id="supplemental_file_input_${masterfileId}_${fileId}"]`, row);
    input.focus();
  });
});

/* Hide form when form is cancelled */
queryAll('button[name="cancel_edit_label"]').forEach(button => {
  button.addEventListener('click', (e) => {
    const row = getHTMLInfo(e, '.supplemental-file-data');

    row.classList.remove('is-editing');

    // Remove form label row
    const captionsSection = query('.captions');
    if (captionsSection) {
      const editingItems = queryAll('.is-editing', captionsSection);
      if (editingItems.length === 1) {
        const editLabelRow = getById('edit-label-row');
        editLabelRow.classList.remove('is-editing');
      }
    }
  });
});

/* After editing, close the form and show the new label */
queryAll('button[name="save_label"]').forEach(button => {
  button.addEventListener('click', (e) => {
    const row = getHTMLInfo(e, '.supplemental-file-data');
    const form = e.target.closest('form');
    const { fileId, masterfileId } = form.dataset;

    row.classList.remove('is-editing');

    // Remove form label row
    const captionsSection = query('.captions');
    if (captionsSection) {
      const editingItems = queryAll('.is-editing', captionsSection);
      if (editingItems.length === 1) {
        const editLabelRow = getById('edit-label-row');
        editLabelRow.classList.remove('is-editing');
      }
    }

    // Remove feedback message after 5 seconds
    setTimeout(function () {
      const alert = query(`small[name="flash-message-${masterfileId}-${fileId}"]`, row);
      const iconSuccess = query('.icon-success', row);
      const iconError = query('.icon-error', row);
      const messageContent = query('.message-content', row);
      iconSuccess.classList.add('d-none');
      iconError.classList.add('d-none');
      messageContent.innerHTML = '';
      if (alert) {
        alert.className = '';
        alert.classList.add('visible-inline');
      }
    }, 5000);
  });
});

/* Show feedback message inline after saving */
queryAll('.supplemental-file-form').forEach(form => {
  form.addEventListener('ajax:success', (event) => {
    const row = event.currentTarget.parentElement;
    const { masterfileId, fileId } = event.currentTarget.dataset;
    // Get machine-generated checkbox input on form submission
    const machineGenInput = query(`input[id="machine_generated_${fileId}"]`, row);
    const isMachineGen = machineGenInput?.checked;

    // Set the label to the new value
    const newLabelInput = query(`input[id="supplemental_file_input_${masterfileId}_${fileId}"]`, row);
    const newLabel = newLabelInput ? newLabelInput.value : '';
    const labelSpan = query(`span[name="label_${masterfileId}_${fileId}"]`, row);
    labelSpan.textContent = newLabel;

    // Show flash message for success
    const messageContent = query('.message-content', row);
    messageContent.innerHTML = 'Successfully updated.';

    // Show/hide icon based on the updated machine-generated form check
    const gearsIcon = query('.fa-gears', row);
    isMachineGen ? gearsIcon.classList.remove('d-none') : gearsIcon.classList.add('d-none');

    const iconSuccess = query('.icon-success', row);
    iconSuccess.classList.remove('d-none');

    const visibleInline = query('.visible-inline', row);
    visibleInline.classList.add('alert');
  });

  form.addEventListener('ajax:error', (event) => {
    const row = event.currentTarget.parentElement;

    // Show flash warning for failed attempt
    const messageContent = query('.message-content', row);
    messageContent.innerHTML = 'Failed to update.';

    const iconError = query('.icon-error', row);
    iconError.classList.remove('d-none');

    const visibleInline = query('.visible-inline', row);
    visibleInline.classList.add('alert');
  });
});

/* Store collapsed section ids in localStorage if available */
queryAll('button[id^="edit_section"]').forEach(button => {
  button.addEventListener('click', (e) => {
    if (!(Modernizr.localStorage || Modernizr.localstorage)) {
      return;
    }

    // Active sections
    let activeSections = JSON.parse(localStorage.getItem('activeSections')) || [];

    const currentSection = e.target.dataset['sectionId'];
    const isCollapsed = e.target.getAttribute('aria-expanded') === 'true';
    if (!isCollapsed) {
      for (let i = 0; i < activeSections.length; i++) {
        if (activeSections[i] === currentSection) {
          activeSections.splice(i, 1);
        }
      }
    } else if (!activeSections.includes(currentSection)) {
      activeSections.push(currentSection);
    }
    localStorage.setItem('activeSections', JSON.stringify(activeSections));
  });
});

/* On page reload; collapse sections which were collapsed previously */
window.addEventListener("load", function () {
  if (!(Modernizr.localStorage || Modernizr.localstorage)) {
    return;
  }

  let activeSections = JSON.parse(localStorage.getItem('activeSections')) || [];

  // Collapse active sections on page
  activeSections.forEach((section) => {
    const sectionDiv = getById('collapseExample' + section);
    if (sectionDiv && !sectionDiv.classList.contains('show')) {
      showOrCollapse(sectionDiv, true);
    }
  });
});

function getHTMLInfo(e, element) {
  return e.target.closest(element);
}
