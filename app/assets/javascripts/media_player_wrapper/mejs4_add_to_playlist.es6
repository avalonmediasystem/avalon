'use strict';

/**
 * Add To Playlist plugin
 *
 * A custom Avalon MediaElement 4 plugin for adding to a playlist
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
    buildaddToPlaylist (player, controls, layers, media) {
        // This allows us to access options and other useful elements already set.
        // Adding variables to the object is a good idea if you plan to reuse
        // those variables in further operations.
        const t = this;
        const addTitle = 'Add to Playlist';
        let addToPlayListObj = t.addToPlayListObj;
        addToPlayListObj.hasPlaylists = addToPlayListObj.playlistEl.dataset.hasPlaylists === 'true';
        addToPlayListObj.isVideo = player.isVideo;

        // Make player instance available outside of this method
        addToPlayListObj.player = player;

        // All code required inside here to keep it private;
        // otherwise, you can create more methods or add variables
        // outside of this scope
        player.addPlaylistButton = document.createElement('div');
    		player.addPlaylistButton.className = t.options.classPrefix + 'button ' + t.options.classPrefix + 'add-to-playlist-button';
    		player.addPlaylistButton.innerHTML = '<button type="button" aria-controls="' + t.id + '" title="' + addTitle + '" ' + 'aria-label="' + addTitle + '" tabindex="0">' + addTitle + '</button>';

        // Add control button to player
    		t.addControlElement(player.addPlaylistButton, 'addToPlaylist');

        // Set up click listener for the control button
        player.addPlaylistButton.addEventListener('click', addToPlayListObj.handleControlClick.bind(t));

        // Set click listeners for form elements
        if (addToPlayListObj.hasPlaylists) {
          addToPlayListObj.addButton.addEventListener('click', addToPlayListObj.handleAddClick.bind(t));
          addToPlayListObj.cancelButton.addEventListener('click', addToPlayListObj.handleCancelClick.bind(t));
        }

        // Set up click listener for Sections
        $('#accordion').on('click', addToPlayListObj.handleSectionLinkClick.bind(t));
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
    cleanaddToPlaylist (player, controls, layers, media) {
      const t = this;
      // Remove the click listener on accordion, which captures all
      // section link clicks
      $('#accordion').off('click');
      $(t.addToPlayListObj.alertEl).hide();
      $(t.addToPlayListObj.playlistEl).hide();
      t.addToPlayListObj.resetForm.apply(t);
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
       * Create a default add to playlist title from @currentStreamInfo
       * Note there is some massaging of the data to get it into place based on whether
       * sections and structural metadata exist.  Perhaps server side could pre-parse the
       * default title to account for scenarios in the future.
       * @return {string} defaultTitle
       */
      createDefaultPlaylistTitle: function () {
        const t = this;
        let addToPlayListObj = t.addToPlayListObj;
        let playlistItemDefaultTitle = addToPlayListObj.player.options.playlistItemDefaultTitle;

        let defaultTitle = addToPlayListObj.hasSections
          ? playlistItemDefaultTitle.slice(0, playlistItemDefaultTitle.lastIndexOf('-')).trim()
          : playlistItemDefaultTitle.slice(playlistItemDefaultTitle.indexOf('-') + 1).trim();

        const currentStream = $('#accordion li a.current-stream');

        if (currentStream.length > 0) {
          let $firstCurrentStream = $(currentStream[0]);
          let re = /\s*\(.*\)$/; // duration notation at end of section title ' (2:00)'
          let structureTitle = $firstCurrentStream.text().replace(re,'').trim();
          let parent = $firstCurrentStream.closest('ul').closest('li').prev();

          while (parent.length > 0) {
            structureTitle = parent.text().trim() + ' - ' + structureTitle;
            parent = parent.closest('ul').closest('li').prev();
          }
          defaultTitle = defaultTitle + ' - ' + structureTitle;
        }

        return defaultTitle;
      },

      /**
       * Handle the 'Add' button click; post form data via ajax and handle response
       * @param  {MouseEvent} e Event generated when Cancel form button clicked
       * @return {void}
       */
      handleAddClick: function (e) {
        const t = this;
        const p = $('#post_playlist_id').val()

        $.ajax({
          url: '/playlists/'+p+'/items',
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
        .done(t.addToPlayListObj.handleAddClickSuccess.bind(t))
        .fail(t.addToPlayListObj.handleAddClickError.bind(t));
      },

      /**
       * Add to playlist AJAX error handler
       * @param  {Object} error AJAX response
       * @return {void}
       */
      handleAddClickError: function(error) {
        const t = this;
        let alertEl = t.addToPlayListObj.alertEl;

        alertEl.classList.remove('alert-success');
        alertEl.classList.add('alert-danger');
        alertEl.classList.add('add_to_playlist_alert_error');
        alertEl.querySelector('p').innerHTML = error.responseJSON.message;
        $(alertEl).slideDown();
      },

      /**
       * Add to playlist AJAX success handler
       * @param  {Object} response AJAX response
       * @return {void}
       */
      handleAddClickSuccess: function(response) {
        const t = this;
        let alertEl = t.addToPlayListObj.alertEl;
        let addToPlayListObj = t.addToPlayListObj;

        alertEl.classList.remove('alert-danger');
        alertEl.classList.add('alert-success');
        alertEl.querySelector('p').innerHTML = response.message;
        $(alertEl).slideDown();
        $(addToPlayListObj.playlistEl).slideUp();
        addToPlayListObj.resetForm.apply(this);
      },

      /**
       * Handle cancel button click; hide form and alert windows.
       * @param  {MouseEvent} e Event generated when Cancel form button clicked
       * @return {void}
       */
      handleCancelClick: function (e) {
        const t = this;
        const addToPlayListObj = t.addToPlayListObj;

        $(addToPlayListObj.alertEl).slideUp();
        $(addToPlayListObj.playlistEl).slideUp();
        addToPlayListObj.resetForm.apply(t);
      },

      /**
       * Handle control button click to toggle Add Playlist display
       * @param  {MouseEvent} e Event generated when Add to Playlist control button clicked
       * @return {void}
       */
      handleControlClick: function (e) {
        const t = this;
        let addToPlayListObj = t.addToPlayListObj;

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
       * @param  {MouseEvent} e [description]
       * @return {void}
       */
      handleSectionLinkClick: function (e) {
        const addToPlayListObj = this.addToPlayListObj;

        if (e.target.tagName.toLowerCase() === 'a') {
          // Only populate new form values if the media player is the same type
          // because if it's a different player type (ie. say audio, then the form
          // will be reset automatically)
          const incomingIsVideo = e.target.dataset['isVideo'] === 'true';
          if (incomingIsVideo === addToPlayListObj.isVideo) {
            addToPlayListObj.populateFormValues.apply(this);
          }
        }
      },

      /**
       * Populate all form fields with default values
       * @return {void}
       */
      populateFormValues: function () {
        const t = this;
        let endTime = '';
        let player = t.addToPlayListObj.player;
        let formInputs = t.addToPlayListObj.formInputs;

        formInputs.title.value = t.addToPlayListObj.createDefaultPlaylistTitle.apply(t);
        formInputs.description.value = '';
        formInputs.start.value = mejs.Utils.secondsToTimeCode(player.getCurrentTime(), true);

        // Calculate end value
        if ($('a.current-stream').length > 0 && typeof $('a.current-stream')[0].dataset.fragmentend !== 'undefined') {
          endTime = parseFloat($('a.current-stream')[0].dataset.fragmentend);
        } else {
          endTime = player.media.duration;
        }
        formInputs.end.value = mejs.Utils.secondsToTimeCode(endTime, true);
      },

      /**
       * Reset all form fields to initial values
       * @return {void}
       */
      resetForm: function () {
        const t = this;
        let formInputs = t.addToPlayListObj.formInputs;

        for (let prop in formInputs) {
          if (prop !== 'playlist') {
            formInputs[prop].value = '';
          }
        }
        t.addToPlayListObj.active = false;
      }
    }

});
