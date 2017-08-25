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
        const addTitle = 'Add to Playlist'
        let addToPlayListObj = t.addToPlayListObj;
        addToPlayListObj.hasPlaylists = addToPlayListObj.playlistEl.dataset.hasPlaylists === 'true';

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

        // Set up click listeners
        player.addPlaylistButton.addEventListener('click', addToPlayListObj.handleControlClick.bind(t));
        if (addToPlayListObj.hasPlaylists) {
          addToPlayListObj.addButton.addEventListener('click', addToPlayListObj.handleAddClick.bind(t));
          addToPlayListObj.cancelButton.addEventListener('click', addToPlayListObj.handleCancelClick.bind(t));
        }
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
    cleanaddToPlaylist (player, controls, layers, media) {},

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
      playlistEl: document.getElementById('add_to_playlist'),

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

        $(addToPlayListObj.alertEl).slideUp(() => {
          $(addToPlayListObj.playlistEl).slideUp();
        });
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
       * Populate all form fields with default values
       * @return {void}
       */
      populateFormValues: function () {
        const t = this;
        let endTime = '';
        let player = t.addToPlayListObj.player;
        let formInputs = t.addToPlayListObj.formInputs;

        formInputs.description.value = '';
        formInputs.start.value = mejs.Utils.secondsToTimeCode(player.getCurrentTime(), true);
        formInputs.title.value = player.options.playlistItemDefaultTitle;

        // Taken from previous coffee script file.  TODO: Verify logic here.
        if ($('a.current-stream').length > 0 && typeof $('a.current-stream')[0].dataset.fragmentend !== 'undefined') {
          endTime = $('a.current-stream')[0].dataset.fragmentend;
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
