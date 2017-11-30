'use strict';

/**
 * Add Markers To Playlist plugin
 *
 * A custom Avalon MediaElement 4 plugin for adding a marker to a playlist
 */

// If plugin needs translations, put here English one in this format:
// mejs.i18n.en["mejs.id1"] = "String 1";
// mejs.i18n.en["mejs.id2"] = "String 2";

// Feature configuration
Object.assign(mejs.MepDefaults, {
    // Any variable that can be configured by the end user belongs here.
    // Make sure is unique by checking API and Configuration file.
    // Add comments about the nature of each of these variables.
});


Object.assign(MediaElementPlayer.prototype, {

    // Public variables (also documented according to JSDoc specifications)

    /**
     * Feature constructor.
     *
     * Always has to be prefixed with `build` and the name that will be used in MepDefaults.features list
     * @param {MediaElementPlayer} player
     * @param {HTMLElement} controls
     * @param {HTMLElement} layers
     * @param {HTMLElement} media
     */
    buildaddMarkerToPlaylist (player, controls, layers, media) {
        // This allows us to access options and other useful elements already set.
        // Adding variables to the object is a good idea if you plan to reuse
        // those variables in further operations.
        const t = this;
        const addTitle = 'Add Marker to Playlist';
        let addMarkerObj = t.addMarkerObj;

        // Make player instance available outside of this method
        addMarkerObj.player = player;
        addMarkerObj.controls = controls;
        addMarkerObj.media = media;

        // All code required inside here to keep it private;
        // otherwise, you can create more methods or add variables
        // outside of this scope
        player.addMarkerToPlaylistButton = document.createElement('div');
    		player.addMarkerToPlaylistButton.className = t.options.classPrefix + 'button ' + t.options.classPrefix + 'add-marker-to-playlist-button';
    		player.addMarkerToPlaylistButton.innerHTML = `<button type="button" aria-controls="${t.id}" title="${addTitle}" aria-label="${addTitle}" tabindex="0">${addTitle}</button>`;

        // Add control button to player
    		t.addControlElement(player.addMarkerToPlaylistButton, 'addMarkerToPlaylist');

        // Set up click listener for the control button which opens
        // and closes the Add Marker to Playlist form
        player.addMarkerToPlaylistButton.addEventListener('click', addMarkerObj.handleControlClick.bind(t));

        // Add all other Markers related event listeners
        addMarkerObj.addEventListeners.apply(t);
    },

    // Optionally, each feature can be destroyed setting a `clean` method

    /**
     * Feature destructor.
     *
     * Always has to be prefixed with `clean` and the name that was used in MepDefaults.features list
     * @param {MediaElementPlayer} player
     * @param {HTMLElement} controls
     * @param {HTMLElement} layers
     * @param {HTMLElement} media
     */
    cleanaddMarkerToPlaylist (player, controls, layers, media) {
      const t = this;

      $(t.addMarkerObj.alertEl).hide();
      $(t.addMarkerObj.formWrapperEl).hide();
      t.addMarkerObj.resetForm.apply(t);
    },

    // Other optional public methods (all documented according to JSDoc specifications)

    /**
     * The 'addMarkerObj' object acts as a namespacer for all Add to Playlist
     * specific variables and methods, so as not to pollute global or MEJS scope.
     * @type {Object}
     */
    addMarkerObj: {
      active: false,
      addButton: document.getElementById('add_marker_submit'),
      alertEl: document.getElementById('add_marker_to_playlist_item_alert'),
      cancelButton: document.getElementById('add_marker_cancel'),
      formInputs: {
        offset: document.getElementById('marker_start'),
        title: document.getElementById('marker_title')
      },
      formWrapperEl: document.getElementById('add_marker_to_playlist_item'),
      markersEl: document.getElementById('markers'),
      player: null,

      /**
       * Add event (mostly click) listeners for marker interaction elements
       * @return {void}
       */
      addEventListeners: function () {
        const t = this;
        const addMarkerObj = this.addMarkerObj;
        const markersEl = document.getElementById('markers');

        // Set click listeners for Add Marker to Playlist form elements
        addMarkerObj.addButton.addEventListener('click', addMarkerObj.handleAdd.bind(t));
        addMarkerObj.cancelButton.addEventListener('click', addMarkerObj.handleCancel.bind(t));

        // Set click listeners on the current markers UI table
        // This could potentially be it's own file, but we hook into the MEJS
        // markers plugin, so for now will keep the functionality coupled.
        addMarkerObj.addMarkersTableListeners.apply(t);
      },

      /**
       * Add event listeners for elements in Markers table rows
       * @return {void}
       */
      addMarkersTableListeners: function () {
        const t = this;
        let addMarkerObj = t.addMarkerObj;
        const $markers = $('#markers');
        const $alertError = $('#marker_item_edit_alert');
        let originalMarkerValues = {};

        // Marker title click; play from marker offset time
        $markers.find('a.marker_title').on('click', (e) => {
          const offset = $(e.target).parents('tr').data('offset');
          addMarkerObj.player.setCurrentTime(offset);
        });

        // Edit button click
        $markers.find('button[name="edit_marker"]').on('click', (e) => {
          const $row = $(e.target).parents('tr');
          const markerId = $row.data('markerId');
          const offset = mejs.Utils.convertSMPTEtoSeconds($row.find('input[name="offset_' + markerId + '"]').val());

          addMarkerObj.disableButtons.apply(t, [$row, true]);
          $(e.target).parents('tr').addClass('is-editing');
          // Track original marker offset value of edited row
          originalMarkerValues[markerId] = offset;
        });

        // Cancel button click
        $markers.find('button[name="marker_edit_cancel"]').on('click', (e) => {
          let $row = $(e.target).parents('tr');
          const markerId = $row.data('markerId');

          addMarkerObj.disableButtons.apply(t, [$row, false]);
          $alertError.slideUp();
          $row.removeClass('is-editing');

          // Remove original marker offset value
          delete(originalMarkerValues[markerId]);
        });

        // Delete button click
        $markers.find('button[name="delete_marker"]').on('click', (e) => {
          let $button = $(e.currentTarget);
          let markerId = $button[0].dataset.markerId;
          let confirmButtonId = 'delete_marker_confirm_' + markerId;
          let cancelButtonId = 'delete_marker_cancel_' + markerId;
          let content = `<p>Are you sure?</p>
                          <button id="${confirmButtonId}" class="btn btn-xs btn-danger">Submit</button>
                          <button id="${cancelButtonId}" class="btn btn-xs btn-primary">No, cancel</button>`;

          // Show popover confirmation
          $button.popover({
            container: '#popover-container-' + $button[0].dataset.markerId,
            content: content,
            html: true,
            placement: 'top'
          });
          $button.popover('show');

          // Delete confirm click
          $('#' + confirmButtonId).on('click', (e) => {
            $.ajax({
              url: '/avalon_marker/' + markerId,
              type: 'POST',
              data: {
                utf: '✓',
                _method: 'delete'
              }
            }).done((response) => {
              const row = addMarkerObj.markersEl.querySelector('tr[data-marker-id="' + response.id + '"]');

              $button.popover('destroy');
              // Remove from list
              row.parentNode.removeChild(row);
              // Update markers in player
              addMarkerObj.updateVisualMarkers.apply(this, [null, parseInt(response.marker.start_time / 1000, 10)]);
            }).fail((error) => {
              console.log('error', error);
            });
          });

          // Delete cancel click
          $('#' + cancelButtonId).on('click', (e) => {
            $button.popover('destroy');
          });
        });

        // Save button click
        $markers.find('button[name="save_marker"]').on('click', (e) => {
          const $tr = $(e.target).parents('tr');
          const markerId = $tr.data('markerId');
          const marker = {
            title: $tr.find('input[name="title_' + markerId + '"]').val(),
            start_time: $tr.find('input[name="offset_' + markerId + '"]').val(),
            marker_edit_save: ''
          }

          // Hide old error messages
          $alertError.hide();

          $.ajax({
            url: '/avalon_marker/' + markerId,
            type: 'POST',
            data: {
              utf: '✓',
              _method: 'patch',
              marker: marker
            }
          })
          .done((response) => {
            const offset = response.marker.start_time/1000;
            const startDisplayTime = mejs.Utils.secondsToTimeCode(offset);

            // Update markers in player
            addMarkerObj.updateVisualMarkers.apply(t, [offset, originalMarkerValues[markerId]]);
            // Remove original marker offset value
            delete(originalMarkerValues[markerId]);
            // Rebuild markers table with updated values
            addMarkerObj.rebuildMarkersTable.apply(t);
          })
          .fail((error) => {
            // Display error message
            const responseText = JSON.parse(error.responseText);
            const msg = responseText.errors[0] || "There was an unknown error updating marker";

            $alertError.find('p').text(msg);
            $alertError.slideDown();
          });
        });
      },

      /**
       * Clear the Add marker to playlist alert box of previous messages
       * @return {void}
       */
      clearAddAlert: function () {
        let alertEl = this.addMarkerObj.alertEl;

        alertEl.classList.remove('alert-success');
        alertEl.classList.remove('alert-danger');
        $(alertEl).empty();
      },

      /**
       * Construct a html table row for the Markers table
       * @param  {Object} obj An object returned from the endpoint for get all markers for a playlist id
       * @return {string} An html string of the <tr> element
       */
      constructTableRow: function (obj) {
        const id = obj.id;
        const title = obj.title;
        const offset = obj.start_time;
        const timeCode = mejs.Utils.secondsToTimeCode(offset);
        let html = `<tr data-offset="${offset}" data-marker-id="${id}"><td>
              <a class="marker_title display-item outline_on" data-offset="${offset}">${title}</a>
              <input name="title_${id}" type="text" class="form-control edit-item outline_on" value="${title}">
            </td>
            <td>
              <span class="marker_start_time display-item">${timeCode}</span>
              <input name="offset_${id}" type="text" class="form-control edit-item outline_on" value="${timeCode}">
            </td>
            <td class="text-right" id="popover-container-${id}">
                <button name="edit_marker" type="button" class="btn btn-default btn-xs edit_marker display-item outline_on">
                  <i class="fa fa-edit" title="Edit"></i> <span class="sm-hidden">Edit</span>
</button>                <button name="save_marker" type="button" class="btn btn-default btn-xs edit-item outline_on">
                  <i class="fa fa-check" title="Save"></i> <span class="sm-hidden">Save</span>
</button>                <button name="marker_edit_cancel" type="button" class="btn btn-danger btn-xs edit-item outline_on">
                  <i class="fa fa-times" title="Cancel"></i> <span class="sm-hidden">Cancel</span>
</button>                <button data-marker-id="${id}" name="delete_marker" class="btn btn-danger btn-xs display-item outline_on">
                  <i class="fa fa-times" title="Delete"></i> <span class="sm-hidden">Delete</span>
                </button>
            </td></tr>`;

          return html;
      },

      /**
       * Disable sibling table row buttons when editing a row
       * @param  {Object} $row jQuery object of current table row being edited
       * @param  {boolean} doDisable Enable or disable sibling buttons?
       * @return {void}
       */
      disableButtons: function ($row, doDisable) {
        const addMarkerObj = this.addMarkerObj;
        let $siblings = $row.siblings();

        $siblings.find('button[name="edit_marker"]').prop({ disabled: doDisable });
        $siblings.find('button[name="delete_marker"]').prop({ disabled: doDisable });
      },

      /**
       * Get all current markers for playlist item
       * @return {Object[]} markers - Array of sorted marker objects
       */
      getMarkers: function (resolve, reject) {
        const playlistItem = mejs4AvalonPlayer.playlistItem;

        $.ajax({
          url: '/playlists/' + playlistItem.playlist_id + '/items/' + playlistItem.id + '.json',
          dataType: 'json'
        }).done((response) => {
          resolve(response);
        }).fail((error) => {
          reject(error);
        });
      },

      /**
       * Handle the 'Add' button click; post form data via ajax and handle response
       * @param  {MouseEvent} e Event generated when Cancel form button clicked
       * @return {void}
       */
      handleAdd: function (e) {
        const t = this;
        const addMarkerObj = t.addMarkerObj;
        const $playlistItem = $('#right-column').find('li.now_playing');
        const playlist_item_id = $playlistItem[0].dataset.playlistItemId;

        // Clear out alerts
        addMarkerObj.clearAddAlert.apply(t);

        $.ajax({
          url: '/avalon_marker',
          type: 'POST',
          data: {
            marker: {
              master_file_id: mejs4AvalonPlayer.currentStreamInfo.id,
              playlist_item_id: playlist_item_id,
              start_time: $('#marker_start').val(),
              title: $('#marker_title').val()
            }
          }
        })
        .done(addMarkerObj.handleAddSuccess.bind(t, $('#marker_start').val()))
        .fail(addMarkerObj.handleAddError.bind(t));
      },

      /**
       * Add to playlist AJAX error handler
       * @param  {Object} error AJAX response
       * @return {void}
       */
      handleAddError: function(error) {
        const t = this;
        let alertEl = t.addMarkerObj.alertEl;

        alertEl.classList.add('alert-danger');
        alertEl.classList.add('add_to_playlist_alert_error');
        error.responseJSON.message.forEach((message) => {
          $(alertEl).append('<p>' + message + '</p>');
        });
        $(alertEl).slideDown();
      },

      /**
       * Add to playlist AJAX success handler
       * @param {string} startTime The marker start time text input value
       * @param  {Object} response AJAX response
       * @return {void}
       */
      handleAddSuccess: function(startTime, response) {
        const t = this;
        const alertEl = t.addMarkerObj.alertEl;
        let $alertEl = $(alertEl);
        let addMarkerObj = t.addMarkerObj;
        const offset = mejs.Utils.convertSMPTEtoSeconds(startTime);

        alertEl.classList.add('alert-success');
        $alertEl.append('<p>' + response.message + '</p>');
        // Add page refresh message if needed
        if (!addMarkerObj.markersEl) {
          $alertEl.append('<p>Please wait while the page refreshes...</p>');
        }
        $alertEl.show('slow');
        $(addMarkerObj.formWrapperEl).slideUp();
        addMarkerObj.resetForm.apply(this);

        // Update visual markers in the player UI
        addMarkerObj.updateVisualMarkers.apply(this, [offset]);

        if (addMarkerObj.markersEl) {
          // Rebuild Markers table
          addMarkerObj.rebuildMarkersTable.apply(this);
        } else {
          // No markers section exists in the DOM yet,
          // need a page refresh to build it (most efficient way)
          window.location.reload();
        }
      },

      /**
       * Handle cancel button click; hide form and alert windows.
       * @param  {MouseEvent} e Event generated when Cancel form button clicked
       * @return {void}
       */
      handleCancel: function (e) {
        const t = this;
        const addMarkerObj = t.addMarkerObj;

        $(addMarkerObj.alertEl).slideUp();
        $(addMarkerObj.formWrapperEl).slideUp();
        addMarkerObj.resetForm.apply(t);
      },

      /**
       * Handle control button click to toggle Add Playlist display
       * @param  {MouseEvent} e Event generated when Add to Playlist control button clicked
       * @return {void}
       */
      handleControlClick: function (e) {
        const t = this;
        let addMarkerObj = t.addMarkerObj;

        if (!addMarkerObj.active) {
          // Close any open alert displays
          $(t.addMarkerObj.alertEl).slideUp();
          // Load default values into form fields
          t.addMarkerObj.populateFormValues.apply(this);
        }
        // Toggle form display
        $(t.addMarkerObj.formWrapperEl).slideToggle();
        // Update active (is showing) state
        t.addMarkerObj.active = !t.addMarkerObj.active;
      },

      /**
       * Populate all form fields with default values
       * @return {void}
       */
      populateFormValues: function () {
        let addMarkerObj = this.addMarkerObj;

        addMarkerObj.formInputs.offset.value = mejs.Utils.secondsToTimeCode(addMarkerObj.player.getCurrentTime(), true);
      },

      /**
       * Reset all form fields to initial values
       * @return {void}
       */
      resetForm: function () {
        const t = this;
        let formInputs = t.addMarkerObj.formInputs;

        /* eslint-disable guard-for-in */
        for (let prop in formInputs) {
          formInputs[prop].value = '';
        }
        t.addMarkerObj.active = false;
        /* eslint-enable guard-for-in */
      },

      /**
       * Re-build the markers table after an add or edit
       * @return {void}
       */
      rebuildMarkersTable: function () {
        const t = this;
        const addMarkerObj = this.addMarkerObj;
        let tBody = addMarkerObj.markersEl.getElementsByTagName('tbody');
        let markersPromise = new Promise(addMarkerObj.getMarkers.bind(t));

        markersPromise.then((response) => {
          let tableRows = response.markers.map((marker) => {
            return addMarkerObj.constructTableRow.apply(t, [marker]);
          });
          // Clear out old table rows
          $(tBody).empty();
          // Insert new table rows
          tableRows.forEach((row) => {
            $(tBody).append(row);
          });
          // Remove old event listeners
          $(addMarkerObj.markersEl).off();
          // Add event listeners to newly created row
          addMarkerObj.addMarkersTableListeners.apply(t);
        });
      },

      /**
       * Update markers in the UI on the player
       * @return {void}
       */
      updateVisualMarkers: function (newOffset, oldOffset) {
        const t = this;
        const addMarkerObj = t.addMarkerObj;
        let markers = addMarkerObj.player.options.markers;

        // Remove old marker data on the player instance
        if (markers.indexOf(oldOffset) > -1 ) {
          markers.splice(markers.indexOf(oldOffset), 1);
        }

        // Add new marker data on the player instance
        markers.push(newOffset);

        // Directly delete current markers from the player UI
        let currentMarkerEls = addMarkerObj.controls.getElementsByClassName(t.options.classPrefix + 'time-marker');
        while(currentMarkerEls[0]) {
          currentMarkerEls[0].parentNode.removeChild(currentMarkerEls[0]);
        }

        // Call methods on the MEJS4 markers plugin to re-build markers and apply to the player
        addMarkerObj.player.buildmarkers(addMarkerObj.player, addMarkerObj.controls, undefined, addMarkerObj.media);
        addMarkerObj.player.setmarkers(addMarkerObj.controls);
      }
    }

});
