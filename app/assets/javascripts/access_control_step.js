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

// Helper function to initialize js-datepicker on date input fields
window.initializeDatepickers = function (container) {
  const root = container || document;
  const dateInputs = queryAll('.date-input:not([data-datepicker-initialized])', root);

  dateInputs.forEach(function (input) {
    const inputId = input.id || input.name;
    let pickerOptions = {
      formatter: (input, date) => {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        input.value = `${year}-${month}-${day}`;
      },
      customDays: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
    };

    let setupRange = (id, isBeginDate) => {
      if (!id) return;
      let pairedInput = null;
      const pairedDateId = isBeginDate ? id.replace('_begin', '_end') : id.replace('_end', '_begin');
      pairedInput = query(`#${pairedDateId}, [name="${pairedDateId}"]`, root);

      if (pairedInput) {
        switch (isBeginDate) {
          case true:
            pickerOptions.onSelect = function (instance, date) {
              pairedInput.datepicker?.setMin(date);
            };
            break;
          case false:
            pickerOptions.onSelect = function (instance, date) {
              pairedInput.datepicker?.setMax(date);
            };
            break;
        }
      }
    };

    // Set up date range constraints for coupled begin and end date selection
    if (inputId) {
      let isBeginDate = inputId.includes('_begin');
      setupRange(inputId, isBeginDate);
    }

    const picker = datepicker(input, pickerOptions);
    input.datepicker = picker;
    input.dataset.datepickerInitialized = 'true';
  });
};

document.addEventListener('DOMContentLoaded', function () {
  // Initialize on page load
  window.initializeDatepickers();

  // Watch for dynamically added content using MutationObserver for Blacklight modals
  const observer = new MutationObserver(function (mutations) {
    mutations.forEach(function (mutation) {
      if (mutation.addedNodes && mutation.addedNodes.length > 0) {
        // Check if any date-input elements were added
        mutation.addedNodes.forEach(function (node) {
          if (node.nodeType === 1) {
            if (node.classList && node.classList.contains('date-input')) {
              window.initializeDatepickers(node.parentElement);
            } else if (node.querySelectorAll) {
              const dateInputs = node.querySelectorAll('.date-input');
              if (dateInputs.length > 0) {
                window.initializeDatepickers(node);
              }
            }
          }
        });
      }
    });
  });

  // Start observing the document for changes
  observer.observe(document.body, {
    childList: true,
    subtree: true
  });
});
