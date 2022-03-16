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
 * Link Back plugin
 *
 * A custom Avalon MediaElement 4 plugin for adding a link back to the repository
 * for the embedded player.  This takes two forms:
 * 1) clickable title that overlays on the top left corner of the player
 * 2) control button with an info icon
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
  buildlinkBack(player, controls, layers, media) {
    // This allows us to access options and other useful elements already set.
    // Adding variables to the object is a good idea if you plan to reuse
    // those variables in further operations.
    const t = this;

    let linkBackObj = t.linkBackObj;

    // Make player instance available outside of this method
    linkBackObj.controls = controls;
    linkBackObj.player = player;

    linkBackObj.controlButtonEl = linkBackObj.createControlButtonEl.apply(t);

    // Add control button to player
    t.addControlElement(linkBackObj.controlButtonEl, 'linkBack');

    // Set up click listener for the control button
    linkBackObj.controlButtonEl.addEventListener(
      'click',
      linkBackObj.handleControlClick.bind(t)
    );

    if (player.isVideo) {
      // Create modal and add it to the DOM
      linkBackObj.titleLinkEl = linkBackObj.createTitleLinkEl.apply(t);

      // Set up listener for hiding title link on play
      media.addEventListener('play', linkBackObj.handlePlay.bind(t));
      // Set up listener for showing title link on pause
      media.addEventListener('pause', linkBackObj.handlePause.bind(t));
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
  cleanlinkBack(player, controls, layers, media) {},

  // Other optional public methods (all documented according to JSDoc specifications)

  /**
   * The 'linkBackObj' object acts as a namespacer for this plugin's
   * specific variables and methods, so as not to pollute global or MEJS scope.
   * @type {Object}
   */
  linkBackObj: {
    titleLinkEl: null,
    controlButtonEl: null,

    createTitleLinkEl: function() {
      let linkBackObj = this.linkBackObj;
      let titleLinkEl = document.getElementById('mejs-title-link');

      // If element already exists, remove it
      if (titleLinkEl) {
        titleLinkEl.parentNode.removeChild(titleLinkEl);
      }
      titleLinkEl = document.createElement('div');
      titleLinkEl.classList.add('mejs__title-link');
      titleLinkEl.id = 'mejs-title-link';
      titleLinkEl.innerHTML =
        '<a href="' +
        linkBackObj.player.options.link_back_url +
        '" target="_blank">' +
        linkBackObj.player.options.embed_title +
        '</a>';
      linkBackObj.controls.parentNode.insertBefore(
        titleLinkEl,
        linkBackObj.controls
      );

      return titleLinkEl;
    },

    createControlButtonEl: function() {
      const t = this;
      let controlButtonEl = document.getElementById('mejs-link-back');

      // If element already exists, remove it
      if (controlButtonEl) {
        controlButtonEl.parentNode.removeChild(controlButtonEl);
      }

      const addTitle = 'View in Repository';
      controlButtonEl = document.createElement('div');
      controlButtonEl.className =
        t.options.classPrefix +
        'button ' +
        t.options.classPrefix +
        'link-back-button';
      controlButtonEl.innerHTML = `<button type="button" aria-controls="${
        t.id
      }" title="${addTitle}" aria-label="${addTitle}" tabindex="0">${addTitle}</button>`;

      return controlButtonEl;
    },

    /**
     * Handle control button click to open Avalon in a separate browser window/tab
     * @param  {MouseEvent} e Event generated when control button clicked
     * @return {void}
     */
    handleControlClick: function(e) {
      return window.open(this.linkBackObj.player.options.link_back_url);
    },

    /**
     * Handle play event to hide title link
     * @param  {Event} e Event generated when player starts playing
     * @return {void}
     */
    handlePlay: function(e) {
      const $titleLinkEl = $(this.linkBackObj.titleLinkEl);
      $titleLinkEl.hide();
    },

    /**
     * Handle pause event to show title link
     * @param  {Event} e Event generated when player is paused
     * @return {void}
     */
    handlePause: function(e) {
      const $titleLinkEl = $(this.linkBackObj.titleLinkEl);
      $titleLinkEl.show();
    }
  }
});
