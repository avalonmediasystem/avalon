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

// Disable the default action for tooltips if the Javascript for the
// inline tip is able to work. Since we know that these will have additional
// data attributes there is no need for another class hook

document.addEventListener('DOMContentLoaded', function () {
  const equalHeightElements = queryAll('.equal-height');
  if (equalHeightElements.length > 0) {
    // Add 'in' class temporarily
    equalHeightElements.forEach(elem => elem.classList.add('in'));

    // Calculate max height
    const heights = Array.from(equalHeightElements).map(elem => elem.offsetHeight);
    const maxHeight = Math.max(...heights);

    // Set all elements to max height and remove 'in' class
    equalHeightElements.forEach(elem => {
      elem.style.height = maxHeight + 'px';
      elem.classList.remove('in');
    });
  }

  queryAll('.form-text .btn-close').forEach(function (element) {
    element.addEventListener('click', function (event) {
      event.preventDefault();
      const parentElement = this.parentElement;
      if (parentElement) {
        const collapse = bootstrap.Collapse.getOrCreateInstance(parentElement);
        collapse.toggle();
      }
    });
  });
});
