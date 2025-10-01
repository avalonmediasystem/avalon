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

// This is for the playlists edit page for sorting playlist items
document.addEventListener('DOMContentLoaded', function () {
  // Display the drag handle
  var dragHandles = document.querySelectorAll('.dd-handle');
  dragHandles.forEach(function (handle) {
    handle.classList.remove('hidden');
  });

  var playlistContainer = document.querySelector('.dd');
  // Initialize drag-and-drop behavior with SortableJS
  var playlistListContainer = document.querySelector('.dd .dd-list');
  if (playlistListContainer) {
    Sortable.create(playlistListContainer, {
      handle: '.dd-handle',
      animation: 150,
      forceFallback: true,
      fallbackClass: 'sortable-fallback',
      onEnd: function (evt) {
        var items = [];
        var listItems = playlistListContainer.querySelectorAll('.dd-item');
        listItems.forEach(function (item, index) {
          items.push({
            id: item.getAttribute('data-id'),
            position: (index + 1).toString()
          });
        });
        var container = document.querySelector('.dd');
        reorderItems(items, container);
      }
    });
  }

  var reorderItems = function (data, container) {
    var playlistId = container.getAttribute('data-playlist_id');
    var items = data;

    /**
     * Show loading overlay while saving the changes.
     * If the user has a slow connection, this provides feedback for the save operation.
     * Without this, if the user navigates to the playlist show page too quickly, the changes
     * may not be persisted and the user will see the old order of items on the edit page on back
     * navigation.
     */
    var overlay = container.querySelector('.playlist-loading-overlay');
    overlay.classList.add('is-loading');
    playlistContainer.classList.add('is-loading');

    fetch('/playlists/' + playlistId + '.json', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ playlist: { items_attributes: items } })
    })
      .then(function (response) {
        return response.json();
      })
      .then(function (data) {
        playlistContainer.classList.remove('is-loading');
        overlay.classList.remove('is-loading');
      })
      .catch(function (error) {
        playlistContainer.classList.remove('is-loading');
        overlay.classList.remove('is-loading');
        console.error('Error updating playlist:', error);
      });

    setItemPositions();
  };

  // Update the position text in the form
  var setItemPositions = function () {
    var textElements = document.querySelectorAll('.dd .position-input');
    textElements.forEach(function (element, index) {
      element.value = index + 1;
    });
  };

  // Initial setting of item positions
  setItemPositions();
});
