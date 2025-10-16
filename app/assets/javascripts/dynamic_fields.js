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

document.addEventListener('DOMContentLoaded', function () {
  const add_button_html = '<button type="button" class="add-dynamic-field btn btn-outline btn-light"><span class="fa fa-plus"></span></button>';
  const remove_button_html = '<button type="button" class="remove-dynamic-field btn btn-outline btn-light"><span class="fa fa-minus"></span></button>';

  document.querySelectorAll('.mb-3.multivalued').forEach(function (multivalued) {
    const inputGroups = multivalued.querySelectorAll('.input-group');
    inputGroups.forEach(function (inputGroup, igIndex) {
      inputGroup.querySelectorAll('input[id]').forEach(input => {
        input.id = input.id + igIndex;
      });
      inputGroup.querySelectorAll('input[data-bs-target]').forEach(input => {
        input.setAttribute('data-bs-target', input.getAttribute('data-bs-target') + igIndex);
      });
    });
    const allButLast = Array.from(inputGroups).slice(0, -1);
    // Add + icon to the last input group
    const lastInputGroup = inputGroups[inputGroups.length - 1];
    if (lastInputGroup) {
      lastInputGroup.insertAdjacentHTML('beforeend', add_button_html);
    }
    // Add - icon to the rest of the input groups
    allButLast.forEach(inputGroup => {
      inputGroup.insertAdjacentHTML('beforeend', remove_button_html);
    });
  });

  document.addEventListener('click', function (e) {
    const addButton = e.target.closest('.add-dynamic-field');
    if (addButton) {
      e.preventDefault();
      const current_input_group = addButton.closest('.input-group');
      // Clone the current input group for the next value
      const new_input_group = current_input_group.cloneNode(true);

      new_input_group.querySelectorAll('input, textarea').forEach(el => el.value = '');
      new_input_group.querySelectorAll('input[id], textarea[id]').forEach(function (el) {
        const idArray = el.id.split('_');
        idArray.push(parseInt(idArray.pop()) + 1);
        el.id = idArray.join('_');
      });

      // Update targets for the cloned input group
      new_input_group.querySelectorAll('input[data-bs-target], textarea[data-bs-target]').forEach(function (el) {
        const target = el.getAttribute('data-bs-target').split('_');
        target.push(parseInt(target.pop()) + 1);
        el.setAttribute('data-bs-target', target.join('_'));
      });

      if (current_input_group.querySelector('.typeahead')) {
        // Add new input group for typeahead field, e.g. Language(s)
        current_input_group.querySelector('.typeahead').setAttribute('open', false);
        const new_autocomplete = new_input_group.querySelector('.typeahead');
        const for_attr = new_autocomplete.getAttribute('for');
        let target = for_attr.split('-')[0].split('_');
        target.push(parseInt(target.pop()) + 1);
        target = target.join('_');
        new_autocomplete.setAttribute('for', target + '-popup');
        const ul = new_autocomplete.querySelector(".autocomplete_popup");
        ul.id = target + '-popup';
        const feedback = new_autocomplete.querySelector(".autocomplete_feedback");
        feedback.id = target + '-popup-feedback';
      } else if (current_input_group.querySelector('.dropdown-menu')) {
        // Add new input group for dropdown field, e.g. Rights Statement
        const firstLink = current_input_group.querySelector('.dropdown-menu li:first-child a');
        const firstSpan = current_input_group.querySelector('.dropdown-menu li:first-child span');
        const dropdown_default_label = firstLink ? firstLink.textContent : '';
        const dropdown_default_value = firstSpan ? firstSpan.textContent : '';

        const dropdownToggleSpan = new_input_group.querySelector('.dropdown-toggle span');
        if (dropdownToggleSpan) dropdownToggleSpan.textContent = dropdown_default_label;
        const hiddenInput = new_input_group.querySelector('input[type="hidden"]');
        if (hiddenInput) hiddenInput.value = dropdown_default_value;
      }

      // Swap + icon for - icon for the current input group
      const addBtn = current_input_group.querySelector('button.add-dynamic-field');
      if (addBtn) addBtn.remove();
      current_input_group.insertAdjacentHTML('beforeend', remove_button_html);

      const textarea = current_input_group.dataset.textarea;
      if (typeof (textarea) !== "undefined") {
        // Add new input group with textarea, e.g. Note(s) field
        const current_textarea = document.getElementById(textarea);
        if (current_textarea) {
          const new_textarea = current_textarea.cloneNode(true);
          new_textarea.value = '';
          const idArray = new_textarea.id.split('_');
          idArray.push(parseInt(idArray.pop()) + 1);
          new_textarea.id = idArray.join('_');
          new_input_group.dataset.textarea = new_textarea.id;

          current_textarea.insertAdjacentElement('afterend', new_input_group);
          new_input_group.insertAdjacentElement('afterend', new_textarea);
        }
      } else {
        // Add new input group for the next value
        current_input_group.insertAdjacentElement('afterend', new_input_group);
      }
    }
  });

  document.addEventListener('click', function (e) {
    const removeButton = e.target.closest('.remove-dynamic-field');
    if (removeButton) {
      e.preventDefault();
      const current_input_group = removeButton.closest('.input-group');
      const textarea = current_input_group.dataset.textarea;
      // Remove textarea associated with the current input group
      if (typeof (textarea) !== "undefined") {
        const textareaEl = document.getElementById(textarea);
        if (textareaEl) textareaEl.remove();
      }
      // Remove the current input group
      current_input_group.remove();
    }
  });
});
