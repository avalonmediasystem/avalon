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

/* Override the search_context so it stops POSTing links which confuses
 * Rails and causes it to redirect to the wrong place. */
document.addEventListener('DOMContentLoaded', () => {
  if (typeof Blacklight != undefined) {
    Blacklight.do_search_context_behavior = function () { };
  }

  document.addEventListener('click', (e) => {
    const btn = e.target;

    /**
     * Retain stateful button behavior after Bootstrap 3.
     * Reference: https://www.robertmullaney.com/2018/10/25/continue-using-data-loading-text-buttons-bootstrap-4-jquery/
     */
    if (btn.classList.contains('btn-stateful-loading') && btn?.dataset?.loadingText != undefined) {
      btn.value = btn.dataset.loadingText;
      btn.style.cursor = 'not-allowed';
      btn.style.opacity = 0.5;
    }
  });

  const showObjectTree = document.getElementById('show_object_tree');
  if (showObjectTree) {
    showObjectTree.addEventListener('click', function () {
      const objectTree = document.getElementById('object_tree');
      if (objectTree) {
        fetch(objectTree.dataset.src)
          .then(response => response.text())
          .then(html => {
            objectTree.innerHTML = html;
          });
      }
    });
  }

  const iOS = !!/(iPad|iPhone|iPod)/g.test(navigator.userAgent);
  function preventDefaultAndStop(e) {
    e.preventDefault();
    e.stopPropagation();
    return false;
  }
  if (iOS) {
    const readonlyInputs = document.querySelectorAll('input[readonly], textarea[readonly]');
    readonlyInputs.forEach(function (input) {
      input.addEventListener('cut', preventDefaultAndStop);
      input.addEventListener('paste', preventDefaultAndStop);
      input.addEventListener('keydown', preventDefaultAndStop);
      input.removeAttribute('readonly');
    });
  }

  window.addEventListener('hashchange', function () {
    var element = document.getElementById(location.hash.substring(1));
    if (element) {
      if (!/^(?:a|select|input|button|textarea)$/i.test(element.tagName)) {
        element.tabIndex = -1;
      }
      element.focus();
    }
  }, false);

  // Set CSS to push the page content above footer
  const contentWrapper = document.querySelector('.content-wrapper');
  const footer = document.getElementById('footer');

  window.addEventListener('resize', () => {
    if (contentWrapper && footer) { }
  });

  function adjustFooterPadding() {
    if (contentWrapper && footer) {
      const footerHeight = window.getComputedStyle(footer).height;
      contentWrapper.style.paddingBottom = footerHeight;
    }
  }

  // Adjust footer on page load
  adjustFooterPadding();

  /* Toggle CSS classes for global search form */
  const searchWrapper = document.querySelector('.global-search-wrapper');
  const searchSubmit = document.querySelector('.global-search-submit');

  function toggleSearchClasses() {
    if (searchWrapper && searchSubmit) {
      if (window.innerWidth < 768) {
        searchWrapper.classList.remove('input-group-lg');
        searchSubmit.classList.remove('btn-primary');
      } else {
        searchWrapper.classList.add('input-group-lg');
        searchSubmit.classList.add('btn-primary');
      }
    }
  }

  // Remove CSS classes at initial page load for mobile screens
  toggleSearchClasses();

  window.addEventListener('resize', () => {
    // Toggle CSS classes when window resizes
    toggleSearchClasses();
    /**
     * Re-set the space between content-wrapper and footer on window resize.
     * With this the main content height is adjusted when orientation changes when
     * using mobile devices, avoiding main content bleeding into the footer.
     */
    adjustFooterPadding();
  }, true);
});
