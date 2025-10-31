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

/**
 * This script will enable support adding 'Add new playlist' and search functionality in
 * add to playlist dropdown menu via tom-select JS library.
 */
document.addEventListener('DOMContentLoaded', () => add_new_playlist_option());

this.add_new_playlist_option = function () {
  const addnew = 'Add new playlist';
  const select_element = getById('post_playlist_id');
  if (!select_element) return;

  const select_options = queryAll('option', select_element);
  let add_success = false;
  let has_new_opt = false;
  let tomSelectInstance = null;
  let lastSearchTerm = '';

  // Helper function to render "Add new playlist" option text
  const renderAddNewPlaylistOption = function (searchTerm) {
    const iconHtml = '<i class="fa fa-plus" aria-hidden="true"></i> ';
    const termText = searchTerm && searchTerm.trim() ? ' "' + searchTerm + '"' : '';
    return iconHtml + '<b>' + addnew + termText + '</b>';
  };

  // Helper function to update "Add new playlist" option with typed search term
  const updateAddNewPlaylistOption = function (dropdown_content, searchTerm) {
    const addNewOption = query('[data-value="' + addnew + '"]', dropdown_content);
    if (addNewOption) {
      const escapedTerm = searchTerm ? escapeHtml(searchTerm) : searchTerm;
      addNewOption.innerHTML = renderAddNewPlaylistOption(escapedTerm);
    }
  };

  const escapeHtml = function (str) {
    return (str + '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  };

  // Add 'Add new playlist' option only when not present
  select_options.forEach(function (option) {
    if (option.value === addnew) {
      has_new_opt = true;
    }
  });
  if (!has_new_opt) {
    // Insert 'Add new playlist' option at the top of the list
    const newOption = new Option(addnew);
    select_element.insertBefore(newOption, select_element.firstChild);
  }

  // Initialize TomSelect
  function initTomSelectWithRetry() {
    if (typeof TomSelect !== 'undefined') {
      const selectEl = getById('post_playlist_id');
      if (!selectEl || selectEl.tomselect) return;

      // Get first playlist option and identify it as default
      const firstRealOption = Array.from(selectEl.options).find(opt => opt.value !== addnew);
      const defaultValue = firstRealOption ? firstRealOption.value : null;

      tomSelectInstance = new TomSelect(selectEl, {
        searchField: ['text'],
        sortField: [
          { field: '$order' },
          { field: 'text', direction: 'asc' }
        ],
        // Override the scoring function for searching
        score: function (search) {
          const searchLower = search.toLowerCase().trim();
          return function (item) {
            const itemTextLower = item.text.toLowerCase();
            // Always show "Add new playlist" option with highest priority
            if (item.text === addnew) return 2;
            // Show playlists that start with the search term
            if (itemTextLower.startsWith(searchLower)) return 1;
            // Hide non-matching playlists
            return 0;
          };
        },
        onInitialize: function () {
          const self = this;
          // Set $order property on options after initialization
          Object.keys(self.options).forEach(function (key) {
            const option = self.options[key];
            // Set "Add new playlist" order 0 to make it appear on top of playlists
            option.$order = (option.text === addnew) ? 0 : 1;
          });
        },
        allowEmptyOption: false,
        hideSelected: false,
        closeAfterSelect: true,
        placeholder: 'Search playlists',
        // Prevent clearing selection with backspace/delete
        onDelete: function () { return false; },
        // Hide search in control and use plugin to show search in dropdown
        controlInput: null,
        // Use 'Drodown Input' to add search at the top of the list
        plugins: ['dropdown_input'],
        onType: function (str) {
          // Remember the search term as user types
          lastSearchTerm = str;
          // Update the "Add new playlist" option text dynamically
          updateAddNewPlaylistOption(this.dropdown_content, str);
        },
        onDropdownOpen: function () {
          // Reset "Add new playlist" option text
          lastSearchTerm = '';
          updateAddNewPlaylistOption(this.dropdown_content, '');

          // Mark search field as readonly to prevent from keyboard popping up for mobile devices
          const IS_TOUCH_ONLY = navigator.maxTouchPoints && navigator.maxTouchPoints > 2 && !window.matchMedia("(pointer: fine").matches;
          if (/Mobi|iPhone/i.test(window.navigator.userAgent) || IS_TOUCH_ONLY) {
            this.control_input.setAttribute('readonly', true);
            // Remove readonly after a short delay to allow typing if user focuses manually
            setTimeout(() => {
              this.control_input.removeAttribute('readonly');
            }, 100);
          }

          // Update selected-option class when dropdown opens
          const currentValue = this.getValue();
          const dropdownOptions = queryAll('.selected-option', this.dropdown_content);
          dropdownOptions.forEach(opt => opt.classList.remove('selected-option'));

          if (currentValue) {
            const selectedOptionEl = query('[data-value="' + currentValue + '"]', this.dropdown_content);
            if (selectedOptionEl) {
              selectedOptionEl.classList.add('selected-option');
              // Scroll the selected option into view within the dropdown container
              const dropdownContainer = this.dropdown_content;
              const containerHeight = dropdownContainer.clientHeight;
              // Center the selected option in the dropdown
              dropdownContainer.scrollTop = selectedOptionEl.offsetTop - (containerHeight / 2) + (selectedOptionEl.offsetHeight / 2);
            }
          }
        },
        onInitialize: function () {
          // Set ARIA attributes for tom-select controls flagged by SiteImprove
          const dropdownList = query('#post_playlist_id-ts-dropdown');
          if (dropdownList) {
            dropdownList.setAttribute('aria-label', 'list of playlists');
          }
          const playlistsCombobox = query('#post_playlist_id-ts-control');
          if (playlistsCombobox) playlistsCombobox.setAttribute('aria-labelledby', 'post_playlist_id');
        },
        render: {
          item: function (data, escape) {
            return `<div>${escape(data.text)}</div>`;
          },
          option: function (data, escape) {
            const isSelected = this.items.indexOf(data.value) !== -1;
            const selectedClass = isSelected ? 'ts-option-custom selected-option' : 'ts-option-custom';
            let content;
            if (data.text === addnew) {
              content = renderAddNewPlaylistOption('');
            } else {
              content = escape(data.text);
            }
            return `<div class="${selectedClass}" data-value="${escape(data.value)}">${content}</div>`;
          },
          no_results: function (data, escape) {
            const searchTerm = escape(data.input);
            return `<div class="ts-option-custom option" data-selectable data-value="${addnew}">
              ${renderAddNewPlaylistOption(searchTerm)}</div>`;
          },
        },
        onChange: function (value) {
          // Remove selected-option class from all options
          const dropdownOptions = queryAll('.selected-option', this.dropdown_content);
          dropdownOptions.forEach(opt => opt.classList.remove('selected-option'));

          // Add selected-option class to the newly selected option
          const selectedOptionEl = query('[data-value="' + value + '"]', this.dropdown_content);
          if (selectedOptionEl) {
            selectedOptionEl.classList.add('selected-option');

            // Scroll the selected option into view within the dropdown container
            const dropdownContainer = this.dropdown_content;
            const optionTop = selectedOptionEl.offsetTop;
            const optionHeight = selectedOptionEl.offsetHeight;
            const containerHeight = dropdownContainer.clientHeight;

            // Center the selected option in the dropdown
            dropdownContainer.scrollTop = optionTop - (containerHeight / 2) + (optionHeight / 2);
          }

          const option = this.options[value];
          if (option && option.text === addnew) {
            showNewPlaylistModal(lastSearchTerm);
            lastSearchTerm = '';
          }
        }
      });

      // Set the first playlist as default selection
      if (defaultValue && tomSelectInstance) {
        tomSelectInstance.setValue(defaultValue, true);
      }

      // Add click handler to toggle dropdown
      if (tomSelectInstance && tomSelectInstance.control) {
        let wasOpen = false;

        // Capture state before TomSelect processes events
        tomSelectInstance.on('dropdown_open', function () { wasOpen = true; });
        tomSelectInstance.on('dropdown_close', function () { wasOpen = false; });

        tomSelectInstance.control.addEventListener('click', function () {
          if (wasOpen) {
            setTimeout(() => {
              tomSelectInstance.close();
            }, 0);
          }
        });
      }
    } else {
      // Retry if TomSelect not loaded yet
      setTimeout(initTomSelectWithRetry, 50);
    }
  }

  // Start initialization
  initTomSelectWithRetry();

  var showNewPlaylistModal = function (playlistName) {
    // Set to defaults first
    const submitBtn = getById('new_playlist_submit');
    const titleInput = getById('playlist_title');
    const commentInput = getById('playlist_comment');
    const visibilityPrivate = getById('playlist_visibility_private');
    const titleError = getById('title_error');
    const modal = getById('add-playlist-modal');
    if (submitBtn) {
      submitBtn.value = 'Create';
      submitBtn.disabled = false;
    }
    if (commentInput) {
      commentInput.value = '';
    }
    if (visibilityPrivate) {
      visibilityPrivate.checked = true;
    }

    // Remove any possible old errors
    if (titleError) {
      titleError.remove();
    }
    if (titleInput) {
      titleInput.value = playlistName;
      titleInput.parentElement.classList.remove('has-error');
    }
    add_success = false;

    // Finally show modal
    if (modal) {
      const bsModal = new bootstrap.Modal(modal);
      bsModal.show();
    }
    return true;
  };

  const addPlaylistModal = getById('add-playlist-modal');
  if (addPlaylistModal) {
    addPlaylistModal.addEventListener('hidden.bs.modal', function () {
      if (!add_success && tomSelectInstance) {
        // Reset to first option that's not "Add new playlist"
        const options = Object.values(tomSelectInstance.options)
          .sort((a, b) => a.text.localeCompare(b.text));
        const firstNonAddNew = options.find(opt => opt.text !== addnew);

        if (firstNonAddNew) {
          tomSelectInstance.setValue(firstNonAddNew.value);
        } else {
          // If no other option, just clear
          tomSelectInstance.clear();
        }
      }
    });
  }

  const playlistForm = getById('playlist_form');
  if (playlistForm) {
    playlistForm.addEventListener('submit', function (e) {
      const titleInput = getById('playlist_title');
      const submitBtn = getById('new_playlist_submit');

      if (titleInput && titleInput.value) {
        if (submitBtn) {
          submitBtn.value = 'Saving...';
          submitBtn.disabled = true;
        }
        return true;
      }

      // Prevent submission if no title
      e.preventDefault();

      const titleError = getById('title_error');
      if (!titleError && titleInput) {
        const errorMsg = document.createElement('h5');
        errorMsg.id = 'title_error';
        errorMsg.className = 'error text-danger';
        errorMsg.textContent = 'Name is required';
        titleInput.insertAdjacentElement('afterend', errorMsg);
        titleInput.parentElement.classList.add('has-error');
      }
      return false;
    });

    // Handle AJAX success
    playlistForm.addEventListener('ajax:success', function (event) {
      const [data, status, xhr] = Array.from(event.detail);
      const modal = getById('add-playlist-modal');

      if (modal) toggleModal(modal, false);

      if (data.errors) {
        console.log(data.errors.title[0]);
      } else {
        add_success = true;
        if (tomSelectInstance) {
          // Set the new playlist option
          tomSelectInstance.addOption({
            value: data.id.toString(),
            text: data.title
          });
          tomSelectInstance.setValue(data.id.toString());
        }
      }
    });
  }
};
