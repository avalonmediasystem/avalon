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
 * Add To Playlist plugin
 *
 * A custom Avalon MediaElement 4 plugin for adding to a playlist
 */

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
  buildaddToPlaylist(player, controls, layers, media) {
    const t = this;
    const addTitle = 'Add to Playlist';
    let addToPlayListObj = t.addToPlayListObj;

    addToPlayListObj.player = player;

    addToPlayListObj.hasPlaylists =
      addToPlayListObj.playlistEl &&
      addToPlayListObj.playlistEl.dataset.hasPlaylists === 'true';

    addToPlayListObj.isVideo = player.isVideo;

    player.cleanaddToPlaylist(player);

    // Create plugin control button for player
    player.addPlaylistButton = document.createElement('div');
    player.addPlaylistButton.className =
      t.options.classPrefix +
      'button ' +
      t.options.classPrefix +
      'add-to-playlist-button';
    player.addPlaylistButton.innerHTML = `<button type="button" aria-controls="${
      t.id
    }" title="${addTitle}" aria-label="${addTitle}" tabindex="0" style="opacity: 0.5; cursor: not-allowed;" disabled>${addTitle}</button>`;

    let playlistBtn = player.addPlaylistButton.childNodes[0];

    let enableBtn = () => {
      if(player.duration > 0) {
        playlistBtn.style.opacity = 1;
        playlistBtn.style.cursor = 'pointer';
        playlistBtn.disabled = false;
        clearInterval(timeCheck);
      }
    }

    // Enable add to playlist  button after derivative is loaded
    let timeCheck = setInterval(enableBtn, 500);

    // Add control button to player
    t.addControlElement(player.addPlaylistButton, 'addToPlaylist');

    // Set up click listener for the control button
    player.addPlaylistButton.addEventListener(
      'click',
      addToPlayListObj.handleControlClick.bind(t)
    );

    // Set click listeners for form elements
    addToPlayListObj.bindHandleAdd = addToPlayListObj.handleAddClick.bind(
      addToPlayListObj
    );
    addToPlayListObj.bindHandleCancel = addToPlayListObj.handleCancelClick.bind(
      addToPlayListObj
    );
    addToPlayListObj.addFormClickListeners();

    // Set up click listener for Sections
    $('#accordion').on(
      'click',
      addToPlayListObj.handleSectionLinkClick.bind(t)
    );
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
  cleanaddToPlaylist(player, controls, layers, media) {
    const t = this;
    let addToPlayListObj = t.addToPlayListObj;

    // Remove the click listener on accordion, which captures all section link clicks
    $('#accordion').off('click');

    $(addToPlayListObj.alertEl).hide();
    $(addToPlayListObj.playlistEl).hide();
    addToPlayListObj.resetForm.apply(addToPlayListObj);

    // Remove Add / Cancel button event listeners
    if (addToPlayListObj.addButton !== null) {
      addToPlayListObj.addButton.removeEventListener(
        'click',
        addToPlayListObj.bindHandleAdd
      );
    }
    if (addToPlayListObj.cancelButton !== null) {
      addToPlayListObj.cancelButton.removeEventListener(
        'click',
        addToPlayListObj.bindHandleCancel
      );
    }
    if (player) {
      if (player.addPlaylistButton) {
        player.addPlaylistButton.remove();
      }
    }
  },

  // Other optional public methods (all documented according to JSDoc specifications)

  /**
   * The 'addToPlayListObj' object acts as a namespacer for all Add to Playlist
   * specific variables and methods, so as not to pollute global or MEJS scope.
   * @type {Object}
   */
  addToPlayListObj: {
    active: false,
    addButton: document.getElementById('add_playlist_item_submit'),
    alertEl: document.getElementById('add_to_playlist_alert'),
    bindHandleAdd: null,
    bindHandleCancel: null,
    cancelButton: document.getElementById('add_playlist_item_cancel'),
    formInputs: {
      description: document.getElementById('playlist_item_description'),
      end: document.getElementById('playlist_item_end'),
      playlist: document.getElementById('post_playlist_id'),
      start: document.getElementById('playlist_item_start'),
      title: document.getElementById('playlist_item_title')
    },
    hasPlaylists: false,
    hasSections: $('#accordion').length > 0,
    isVideo: null,
    playlistEl: document.getElementById('add_to_playlist'),

    /**
     * Add click listeners to the Add Playlists form buttons
     * @function addFormClickListeners
     * @return {void}
     */
    addFormClickListeners: function() {
      const t = this;

      if (t.hasPlaylists) {
        t.addButton.addEventListener('click', t.bindHandleAdd);
        t.cancelButton.addEventListener('click', t.bindHandleCancel);
      }
    },

    /**
     * Create a default add to playlist title from @currentStreamInfo
     * Note there is some massaging of the data to get it into place based on whether
     * sections and structural metadata exist.  Perhaps server side could pre-parse the
     * default title to account for scenarios in the future.
     * @function createDefaultPlaylistTitle
     * @return {string} defaultTitle
     */
    createDefaultPlaylistTitle: function() {
      const t = this;
      let addToPlayListObj = t.addToPlayListObj;
      let defaultTitle =
        addToPlayListObj.player.options.playlistItemDefaultTitle;

      const currentStream = $('#accordion li a.current-stream');

      if (currentStream.length > 0) {
        let $firstCurrentStream = $(currentStream[0]);
        let re1 = /^\s*\d\.\s*/; // index number in front of section title '1. '
        let re2 = /\s*\(.*\)$/; // duration notation at end of section title ' (2:00)'
        let structureTitle = $firstCurrentStream
          .text()
          .replace(re1, '')
          .replace(re2, '')
          .trim();
        let parent = $firstCurrentStream
          .closest('ul')
          .closest('li')
          .prev();

        while (parent.length > 0) {
          structureTitle = parent.text().trim() + ' - ' + structureTitle;
          parent = parent
            .closest('ul')
            .closest('li')
            .prev();
        }
        defaultTitle = defaultTitle + ' - ' + structureTitle;
      }

      return defaultTitle;
    },

    /**
     * Checks whether the form elements which make up the Add To Playlist form are
     * present in the DOM.  If no playlists have been created, the values will be 'null'.
     * If playlists have been created, then the values will be DOM element references.
     * @function formHasDefinedInputs
     * @return {Boolean} Does the Add to Playlist form have DOM element inputs?
     */
    formHasDefinedInputs: function() {
      let hasInputs = true;
      const formInputs = this.formInputs;

      for (let prop in formInputs) {
        if (!formInputs[prop]) {
          hasInputs = false;
        }
      }
      return hasInputs;
    },

    /**
     * Handle the 'Add' button click; post form data via ajax and handle response
     * @function handleAddClick
     * @param  {MouseEvent} e Event generated when Cancel form button clicked
     * @return {void}
     */
    handleAddClick: function(e) {
      const t = this;
      const p = $('#post_playlist_id').val();

      $.ajax({
        url: '/playlists/' + p + '/items',
        type: 'POST',
        data: {
          playlist_item: {
            master_file_id: mejs4AvalonPlayer.currentStreamInfo.id,
            title: $('#playlist_item_title').val(),
            comment: $('#playlist_item_description').val(),
            start_time: $('#playlist_item_start').val(),
            end_time: $('#playlist_item_end').val()
          }
        }
      })
        .done(t.handleAddClickSuccess.bind(t))
        .fail(t.handleAddClickError.bind(t));
    },

    /**
     * Add to playlist AJAX error handler
     * @function handleAddClickError
     * @param  {Object} error AJAX response
     * @return {void}
     */
    handleAddClickError: function(error) {
      const t = this;
      let alertEl = t.alertEl;
      let message = error.statusText || 'There was an error adding to playlist';
      if (error.responseJSON && error.responseJSON.message) {
        message = error.responseJSON.message.join('<br/>');
      }
      alertEl.classList.remove('alert-success');
      alertEl.classList.add('alert-danger');
      alertEl.classList.add('add_to_playlist_alert_error');
      alertEl.querySelector('p').innerHTML = 'ERROR: ' + message;
      $(alertEl).slideDown();
    },

    /**
     * Add to playlist AJAX success handler
     * @function handleAddClickSuccess
     * @param  {Object} response AJAX response
     * @return {void}
     */
    handleAddClickSuccess: function(response) {
      const t = this;
      let alertEl = t.alertEl;

      alertEl.classList.remove('alert-danger');
      alertEl.classList.add('alert-success');
      alertEl.querySelector('p').innerHTML = response.message;
      $(alertEl).slideDown();
      $(t.playlistEl).slideUp();
      t.resetForm();
    },

    /**
     * Handle cancel button click; hide form and alert windows.
     * @function handleCancelClick
     * @param  {MouseEvent} e Event generated when Cancel form button clicked
     * @return {void}
     */
    handleCancelClick: function(e) {
      const t = this;

      $(t.alertEl).slideUp();
      $(t.playlistEl).slideUp();
      t.resetForm();
    },

    /**
     * Handle control button click to toggle Add Playlist display
     * @function handleControlClick
     * @param  {MouseEvent} e Event generated when Add to Playlist control button clicked
     * @return {void}
     */
    handleControlClick: function(e) {
      const t = this;
      let addToPlayListObj = t.addToPlayListObj;
      if (addToPlayListObj.player.isFullScreen) {
        addToPlayListObj.player.exitFullScreen();
      }
      if (!addToPlayListObj.active) {
        // Close any open alert displays
        $(t.addToPlayListObj.alertEl).slideUp();

        if (addToPlayListObj.hasPlaylists) {
          // Load default values into form fields
          t.addToPlayListObj.populateFormValues.apply(this);
        }
      }
      // Toggle form display
      $(t.addToPlayListObj.playlistEl).slideToggle();
      // Update active (is showing) state
      t.addToPlayListObj.active = !t.addToPlayListObj.active;
    },

    /**
     * Handle click events on the Sections and structural metadata links.
     * @function handleSectionLinkClick
     * @param  {MouseEvent} e
     * @return {void}
     */
    handleSectionLinkClick: function(e) {
      const addToPlayListObj = this.addToPlayListObj;

      if (e.target.tagName.toLowerCase() === 'a') {
        // Only populate new form values if the media player is the same type
        // because if it's a different player type (ie. say audio, then the form
        // will be reset automatically)
        const incomingIsVideo = e.target.dataset['isVideo'] === 'true';
        if (addToPlayListObj.formHasDefinedInputs() && incomingIsVideo === addToPlayListObj.isVideo) {
          addToPlayListObj.populateFormValues.apply(this);
        }
      }
    },

    /**
     * Populate all form fields with default values
     * @function populateFormValues
     * @return {void}
     */
    populateFormValues: function() {
      const t = this;
      let startTime = '';
      let endTime = '';
      let player = t.addToPlayListObj.player;
      let formInputs = t.addToPlayListObj.formInputs;

      formInputs.title.value = t.addToPlayListObj.createDefaultPlaylistTitle.apply(
        t
      );
      formInputs.description.value = '';
      startTime = player.getCurrentTime();
      formInputs.start.value = mejs.Utils.secondsToTimeCode(startTime, true, false, 25, 3);

      // Calculate end value
      if (
        $('a.current-stream').length > 0 &&
        typeof $('a.current-stream')[0].dataset.fragmentend !== 'undefined'
      ) {
        endTime = parseFloat($('a.current-stream')[0].dataset.fragmentend);
      } else {
        endTime = player.media.duration;
      }
      formInputs.end.value = mejs.Utils.secondsToTimeCode(endTime, true, false, 25, 3);
    },

    /**
     * Reset all form fields to initial values
     * @function resetForm
     * @return {void}
     */
    resetForm: function() {
      const t = this;
      let formInputs = t.formInputs;

      for (let prop in formInputs) {
        if (formInputs[prop] !== null && prop !== 'playlist') {
          formInputs[prop].value = '';
        }
      }
      t.active = false;
    }
  }
});
