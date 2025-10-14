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

document.addEventListener('DOMContentLoaded', function() {
  const section_form = document.querySelector('#associated_files form');
  const button_form = document.querySelector('#workflow_buttons form');

  if (section_form && button_form) {
    const textInputs = section_form.querySelectorAll('input[type=text]');

    textInputs.forEach(function(input) {
      input.addEventListener('change', function() {
        const inputId = this.getAttribute('id');
        const inputName = this.getAttribute('name');
        const inputValue = this.value;
        const double_id = `${inputId}_double`;

        let double = button_form.querySelector(`input[id='${double_id}']`);

        if (!double) {
          double = document.createElement('input');
          double.type = 'hidden';
          double.id = double_id;
          double.name = inputName;
          double.value = inputValue;
          button_form.appendChild(double);
        } else {
          double.value = inputValue;
        }
      });
    });
  }

  const fileInput = document.getElementById('file-input');
  if (fileInput) {
    fileInput.addEventListener('change', function() {
      const submitButtons = document.querySelectorAll('.fileinput-submit');
      submitButtons.forEach(function(button) {
        button.disabled = false;
      });
    });
  }
});
