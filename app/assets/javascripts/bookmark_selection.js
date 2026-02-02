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

/**
 * Manages selection state for bookmarks page
 */
class BookmarkSelectionManager {
  constructor() {
    this.selectedIds = new Set();
    this.initializeEventListeners();
    this.selectAllOnLoad();
    this.updateUI();
  }

  selectAllOnLoad() {
    // Mark all items as selected on page load
    document.querySelectorAll('.bookmark-selection').forEach(cb => {
      cb.checked = true;
      this.selectedIds.add(cb.dataset.documentId);
    });
  }

  /**
   * Initialize event listeners for:
   * - individual document selection checkboxes
   * - 'Select All' checkbox
   * - for checking selection before performing actions
   */
  initializeEventListeners() {
    // Select checbox for each document
    document.querySelectorAll('.bookmark-selection').forEach(checkbox => {
      checkbox.addEventListener('change', (e) => this.handleSelectionChange(e));
    });

    // Select All checkbox
    const selectAll = document.getElementById('bookmarks_selectall');
    if (selectAll) {
      selectAll.addEventListener('change', (e) => this.handleSelectAll(e));
    }

    // Form submission for selected items
    document.querySelectorAll('form[data-requires-selection]').forEach(form => {
      form.addEventListener('submit', (e) => this.handleFormSubmit(e));
    });

    // Check for if all items on page are selected
    document.querySelectorAll('a[data-requires-selection], button[data-requires-selection], .bulk-actions[data-requires-selection] a').forEach(el => {
      el.addEventListener('click', (e) => this.handleActionClick(e));
    });
  }

  handleSelectionChange(e) {
    const id = e.target.dataset.documentId;
    if (e.target.checked) {
      this.selectedIds.add(id);
    } else {
      this.selectedIds.delete(id);
    }
    this.updateUI();
  }

  handleSelectAll(e) {
    const checkboxes = document.querySelectorAll('.bookmark-selection');
    checkboxes.forEach(cb => {
      cb.checked = e.target.checked;
      const id = cb.dataset.documentId;
      if (e.target.checked) {
        this.selectedIds.add(id);
      } else {
        this.selectedIds.delete(id);
      }
    });
    this.updateUI();
  }

  handleFormSubmit(e) {
    const form = e.target;

    // Remove any existing id[] inputs to avoid duplicates
    form.querySelectorAll('input[name="id[]"]').forEach(input => input.remove());

    // Add selected IDs to form
    this.selectedIds.forEach(id => {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = 'id[]';
      input.value = id;
      form.appendChild(input);
    });
  }

  /**
   * Check if all items are selected before allowing actions. If all items are not
   * selected, show alert and prevent action.
   * Skip for 'Clear selected items' button.
   * @param {Event} e click event on toolbar action
   */
  handleActionClick(e) {
    // Allow 'Clear selected items' button to work on partial selection
    if (e.target.dataset.testid === 'remove-selected-btn') {
      return;
    }

    const totalItemsCount = document.querySelectorAll('.bookmark-selection').length;
    // If not all items are selected, show alert and prevent action
    if (totalItemsCount > this.selectedIds.size) {
      window.alert("Please use 'Clear selected items' to remove deselected items before performing actions on a subset.");
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
  }

  /**
   * When item selection changes;
   * - update 'Select All' checkbox state -> checked/unchecked/indeterminate
   * - update selection count display next to 'Select All' checkbox
   * - enables/disables action buttons and 'Clear selected items' button
   */
  updateUI() {
    const hasSelection = this.selectedIds.size > 0;

    // Update 'Select All' checkbox state
    const selectAll = document.getElementById('bookmarks_selectall');
    const allCheckboxes = document.querySelectorAll('.bookmark-selection');

    if (selectAll && allCheckboxes.length > 0) {
      const checkedCount = Array.from(allCheckboxes).filter(cb => cb.checked).length;
      const allChecked = checkedCount === allCheckboxes.length;
      const someChecked = checkedCount > 0;

      selectAll.checked = allChecked;
      selectAll.indeterminate = someChecked && !allChecked;
    }

    // Update selection count
    const countDisplay = document.getElementById('selection-count');
    if (countDisplay) {
      if (hasSelection) {
        countDisplay.textContent = `(${this.selectedIds.size} selected)`;
        countDisplay.classList.remove('d-none');
      } else {
        countDisplay.classList.add('d-none');
      }
    }

    // Enable/disable buttons and form submit buttons
    document.querySelectorAll('[data-requires-selection], .bulk-actions[data-requires-selection] a, form[data-requires-selection] input[type="submit"]').forEach(el => {
      if (hasSelection) {
        el.classList.remove('disabled');
        el.removeAttribute('aria-disabled');
        el.removeAttribute('tabindex');
        el.removeAttribute('disabled');
      } else {
        el.classList.add('disabled');
        el.setAttribute('aria-disabled', 'true');
        el.setAttribute('tabindex', '-1');
        if (el.tagName === 'INPUT') {
          el.setAttribute('disabled', 'disabled');
        }
      }
    });
  }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelector('.bookmark-selection')) {
    window.bookmarkSelectionManager = new BookmarkSelectionManager();
  }
});
