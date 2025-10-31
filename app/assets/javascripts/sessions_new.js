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

document.addEventListener('DOMContentLoaded', function () {
  document.addEventListener('click', function (event) {
    const target = event.target.closest('a[data-trigger="show-email"]');
    if (target) {
      const emailBox = getById('email-box');
      const signInSelect = getById('sign-in-select');
      const signInButtons = getById('sign-in-buttons');

      if (emailBox) emailBox.classList.toggle('hidden');
      if (signInSelect) signInSelect.classList.toggle('hidden');
      if (signInButtons) signInButtons.classList.toggle('hidden');
    }
  });

  let searchParams = new URLSearchParams(window.location.search);
  if (searchParams.has('email')) {
    const emailBox = getById('email-box');
    const signInSelect = getById('sign-in-select');
    const signInButtons = getById('sign-in-buttons');

    if (emailBox) emailBox.style.display = 'block';
    if (signInSelect) signInSelect.style.display = 'none';
    if (signInButtons) signInButtons.style.display = 'none';
  }
});
