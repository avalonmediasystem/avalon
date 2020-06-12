// Copyright 2011-2018, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.

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
  buildaddMarkerToPlaylist(player, controls, layers, media) {
    // This allows us to access options and other useful elements already set.
    // Adding variables to the object is a good idea if you plan to reuse
    // those variables in further operations.
    const t = this;
    const addTitle = 'Add Marker to Playlist';
    let addMarkerObj = t.addMarkerObj;
    addMarkerObj.mejsMarkersHelper = new MEJSMarkersHelper();

    // Make player instance available outside of this method
    addMarkerObj.player = player;
    addMarkerObj.controls = controls;
    addMarkerObj.media = media;

    // Configure player control button to toggle plugin Adding Marker functionality
    player.addMarkerToPlaylistButton = document.createElement('div');
    player.addMarkerToPlaylistButton.className =
      t.options.classPrefix +
      'button ' +
      t.options.classPrefix +
      'add-marker-to-playlist-button';
    player.addMarkerToPlaylistButton.innerHTML = `<button type="button" aria-controls="${
      t.id
    }" title="${addTitle}" aria-label="${addTitle}" tabindex="0">${addTitle}</button>`;

    // Add control button to player
    t.addControlElement(
      player.addMarkerToPlaylistButton,
      'addMarkerToPlaylist'
    );

    // Set up click listener for the control button which opens
    // and closes the Add Marker to Playlist form
    player.addMarkerToPlaylistButton.addEventListener(
      'click',
      addMarkerObj.handleControlClick.bind(t)
    );

    // Variable references to the click event listener callback.  Pass this to avoid duplicate event processing
    addMarkerObj.bindHandleAdd = addMarkerObj.handleAdd.bind(addMarkerObj);
    addMarkerObj.bindHandleCancel = addMarkerObj.handleCancel.bind(
      addMarkerObj
    );

    // Add all other Markers related event listeners
    addMarkerObj.addEventListeners();
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
  cleanaddMarkerToPlaylist(player, controls, layers, media) {
    const t = this;

    if (t.addMarkerObj.addButton) {
      t.addMarkerObj.addButton.removeEventListener(
        'click',
        t.addMarkerObj.bindHandleAdd
      );
    }
    if (t.addMarkerObj.cancelButton) {
      t.addMarkerObj.cancelButton.removeEventListener(
        'click',
        t.addMarkerObj.bindHandleCancel
      );
    }

    $(t.addMarkerObj.alertEl).hide();
    $(t.addMarkerObj.formWrapperEl).hide();
    t.addMarkerObj.resetForm();
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
    bindHandleCancel: null,
    bindHandleAdd: null,
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
    addEventListeners: function() {
      let t = this;

      // Set click listeners for Add Marker to Playlist form elements
      if (t.addButton) {
        t.addButton.addEventListener('click', t.bindHandleAdd);
      }
      if (t.cancelButton) {
        t.cancelButton.addEventListener('click', t.bindHandleCancel);
      }
      // Set click listeners on the current markers UI table
      // t.mejsMarkersHelper.addMarkersTableListeners();
    },

    /**
     * Clear the Add marker to playlist alert box of previous messages
     * @function clearAddAlert
     * @return {void}
     */
    clearAddAlert: function() {
      let alertEl = this.alertEl;

      alertEl.classList.remove('alert-success');
      alertEl.classList.remove('alert-danger');
      $(alertEl)
        .find('p')
        .remove();
    },

    /**
     * Handle the 'Add' button click; post form data via ajax and handle response
     * @function handleAdd
     * @param  {MouseEvent} e Event generated when Cancel form button clicked
     * @return {void}
     */
    handleAdd: function(e) {
      const t = this;
      const playlistIds = t.mejsMarkersHelper.getCurrentPlaylistIds();

      // Clear out alerts
      t.clearAddAlert();

      $.ajax({
        url: '/avalon_marker',
        type: 'POST',
        data: {
          marker: {
            master_file_id: mejs4AvalonPlayer.currentStreamInfo.id,
            playlist_item_id: playlistIds.playlistItemId,
            start_time: $('#marker_start').val(),
            title: $('#marker_title').val()
          }
        }
      })
        .done(t.handleAddSuccess.bind(t, $('#marker_start').val(), playlistIds))
        .fail(t.handleAddError.bind(t));
    },

    /**
     * Add to playlist AJAX error handler
     * @function handleAddError
     * @param  {Object} error AJAX response
     * @return {void}
     */
    handleAddError: function(error) {
      const t = this;
      let alertEl = t.alertEl;

      alertEl.classList.add('alert-danger');
      alertEl.classList.add('add_to_playlist_alert_error');
      error.responseJSON.message.forEach(message => {
        $(alertEl).append('<p>' + message + '</p>');
      });
      $(alertEl).slideDown();
    },

    /**
     * Add to playlist AJAX success handler
     * @function handleAddSuccess
     * @param {string} startTime The marker start time text input value
     * @param  {Object} response AJAX response
     * @return {void}
     */
    handleAddSuccess: function(startTime, playlistIds, response) {
      const t = this;
      const alertEl = t.alertEl;
      let $alertEl = $(alertEl);
      const offset = mejs.Utils.convertSMPTEtoSeconds(startTime);

      alertEl.classList.add('alert-success');
      $alertEl.append('<p>' + response.message + '</p>');
      // Add page refresh message if needed
      if (!t.markersEl) {
        $alertEl.append('<p>Please wait while the page refreshes...</p>');
      }
      $alertEl.show('slow');
      $(t.formWrapperEl).slideUp();
      t.resetForm();

      // Update visual markers in player's time rail
      t.mejsMarkersHelper.updateVisualMarkers();

      if (t.markersEl) {
        // Rebuild Markers table
        t.mejsMarkersHelper.rebuildMarkersTable();
      } else {
        // No markers section exists in the DOM yet,
        // need a page refresh to build it (most efficient way)
        window.location.reload();
      }
    },

    /**
     * Handle cancel button click; hide form and alert windows.
     * @function handleCancel
     * @param  {MouseEvent} e Event generated when Cancel form button clicked
     * @return {void}
     */
    handleCancel: function(e) {
      const t = this;

      $(t.alertEl).slideUp();
      $(t.formWrapperEl).slideUp();
      t.resetForm();
    },

    /**
     * Handle control button click to toggle Add marker to playlist item display
     * @function handleControlClick
     * @param  {MouseEvent} e Event generated when Add Marker to Playlist control button clicked
     * @return {void}
     */
    handleControlClick: function(e) {
      const t = this;
      let addMarkerObj = t.addMarkerObj;
      
      // Exit full screen
      if(addMarkerObj.player.isFullScreen) {
        addMarkerObj.player.exitFullScreen();
        // Reload the form with new values
        if(addMarkerObj.active) {
          $(t.addMarkerObj.formWrapperEl).slideToggle();
          t.addMarkerObj.active = !t.addMarkerObj.active;
        }
      }

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
      // Disable ME.js keyboard shortcuts when form is displayed
      t.addMarkerObj.player.options.enableKeyboard = false;
    },

    /**
     * Populate all form fields with default values
     * @function populateFormValues
     * @return {void}
     */
    populateFormValues: function() {
      let addMarkerObj = this.addMarkerObj;

      addMarkerObj.formInputs.offset.value = mejs.Utils.secondsToTimeCode(
        addMarkerObj.player.getCurrentTime(), true, false, 25, 3);
    },

    /**
     * Reset all form fields to initial values
     * @function resetForm
     * @return {void}
     */
    resetForm: function() {
      const t = this;
      let formInputs = t.formInputs;

      for (const prop in formInputs) {
        if (formInputs.hasOwnProperty(prop) && formInputs[prop]) {
          formInputs[prop].value = '';
        }
      }
      t.active = false;
      // Enable ME.js keyboard shortcuts when form closes
      t.player.options.enableKeyboard = true;
    }
  }
});
