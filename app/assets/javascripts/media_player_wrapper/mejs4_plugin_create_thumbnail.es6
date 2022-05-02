// Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
 * Add Thumbnail Selector plugin
 *
 * A custom Avalon MediaElement 4 plugin for creating a thumbnail (still image) from a video
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
  buildcreateThumbnail(player, controls, layers, media) {
    // This allows us to access options and other useful elements already set.
    // Adding variables to the object is a good idea if you plan to reuse
    // those variables in further operations.
    const t = this;
    const addTitle = 'Create Thumbnail';
    let createThumbnailObj = t.createThumbnailObj;

    if (!player.isVideo) {
      // No support for audio yet
      return;
    } else {
      createThumbnailObj.isVideo = player.isVideo;
    }

    // Make player instance available outside of this method
    createThumbnailObj.player = player;

    // All code required inside here to keep it private;
    // otherwise, you can create more methods or add variables
    // outside of this scope
    player.createThumbnailButton = document.createElement('div');
    player.createThumbnailButton.className =
      t.options.classPrefix +
      'button ' +
      t.options.classPrefix +
      'create-thumbnail-button';
    player.createThumbnailButton.innerHTML = `<button type="button" aria-controls="${
      t.id
    }" title="${addTitle}" aria-label="${addTitle}" tabindex="0">${addTitle}</button>`;

    // Add control button to player
    t.addControlElement(player.createThumbnailButton, 'createThumbnail');

    // Create modal and add it to the DOM
    createThumbnailObj.modalEl = createThumbnailObj.createModalEl.apply(t);

    // Set up click listener for the control button
    player.createThumbnailButton.addEventListener(
      'click',
      createThumbnailObj.handleControlClick.bind(t)
    );

    // Set up click listener for modal submit button now that it's created
    $('#create-thumbnail-submit-button').on(
      'click',
      createThumbnailObj.handleUpdatePosterClick.bind(t)
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
  cleancreateThumbnail(player, controls, layers, media) {},

  // Other optional public methods (all documented according to JSDoc specifications)

  /**
   * The 'createThumbnailObj' object acts as a namespacer for this plugin's
   * specific variables and methods, so as not to pollute global or MEJS scope.
   * @type {Object}
   */
  createThumbnailObj: {
    baseUrl: null,
    isVideo: null,
    modalEl: null,
    offset: null,

    createModalEl: function() {
      let createThumbnailObj = this.createThumbnailObj;
      let modalEl = document.getElementById('create-thumbnail-modal');

      // If modal already exists, remove it
      if (modalEl) {
        modalEl.parentNode.removeChild(modalEl);
      }
      modalEl = document.createElement('div');
      modalEl.classList.add('modal');
      modalEl.classList.add('fade');
      modalEl.classList.add('in');
      modalEl.id = 'create-thumbnail-modal';
      modalEl.innerHTML = `
        <div class="modal-dialog modal-lg" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">×</span></button>
              <h4 class="modal-title">Update Poster Image</h4>
            </div>
            <div class="modal-body text-center">
              <p><img class="img-polaroid img-fluid"></p>
              <div class="alert alert-warning alert-dismissible" role="alert">
                <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                This will update the poster and thumbnail images for this video.
              </div>
            </div>
            <div class="modal-footer">
              <button data-dismiss="modal" class="btn btn-default">Cancel</button>
              <button id="create-thumbnail-submit-button" class="btn btn-primary">Update Poster Image</button>
            </div>
          </div>
        </div>
        `;
      document.body.appendChild(modalEl);

      return modalEl;
    },

    /**
     * Handle the 'Update Poster Image' button click; post form data via ajax and handle response
     * @param  {MouseEvent} e Event generated when Cancel form button clicked
     * @return {void}
     */
    handleUpdatePosterClick: function(e) {
      const createThumbnailObj = this.createThumbnailObj;
      const modalBody = createThumbnailObj.modalEl.getElementsByClassName(
        'modal-body'
      )[0];

      // Put in a loading spinner and disable buttons to prevent double clicks
      modalBody.classList.add('spinner');
      $(createThumbnailObj.modalEl)
        .find('button')
        .attr({ disabled: true });

      $.ajax({
        url: createThumbnailObj.baseUrl + '/still',
        type: 'POST',
        data: {
          offset: createThumbnailObj.offset
        }
      })
        .done(response => {
          $(createThumbnailObj.modalEl).modal('hide');
        })
        .fail(error => {
          console.log(error);
        })
        .always(() => {
          modalBody.classList.remove('spinner');
          $(createThumbnailObj.modalEl)
            .find('button')
            .attr({ disabled: false });
        });
    },

    /**
     * Handle control button click to toggle Add Playlist display
     * @param  {MouseEvent} e Event generated when control button clicked
     * @return {void}
     */
    handleControlClick: function(e) {
      let createThumbnailObj = this.createThumbnailObj;
      let player = createThumbnailObj.player;

      if (player.isFullScreen) {
        player.exitFullScreen();
      }

      const $modalEl = $(createThumbnailObj.modalEl);
      let $imgPolaroid = $modalEl.find('.img-polaroid');

      // Grab environmental variables
      createThumbnailObj.baseUrl =
        '/master_files/' + player.avalonWrapper.currentStreamInfo.id;
      createThumbnailObj.offset = player.getCurrentTime();

      if ($imgPolaroid.length > 0) {
        let src =
          createThumbnailObj.baseUrl +
          '/poster?offset=' +
          createThumbnailObj.offset +
          '&preview=true';

        // Display a preview of thumbnail to user
        $imgPolaroid.attr('src', src);
        $imgPolaroid.fadeIn('slow');
      }
      $modalEl.modal('show');
    }
  }
});
