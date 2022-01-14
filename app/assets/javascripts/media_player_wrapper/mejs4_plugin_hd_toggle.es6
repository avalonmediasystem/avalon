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
 * HD Toggle plugin
 *
 * A custom Avalon MediaElement 4 plugin for toggling between 2 sources
 */

// Translations (English required)
mejs.i18n.en['mejs.hd-toggle'] = 'Toggle between HD and SD quality';

// Feature configuration
Object.assign(mejs.MepDefaults, {
  /**
   * @type {String}
   */
  hdToggleLabel: 'HD',
  /**
   * @type {String}
   */
  hdToggleText: null,
  /**
   * @type {String}
   */
  hdToggleOn: true,
  /**
   * @type {String}
   */
  hdToggleBetween: ['high', 'medium']
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
  /* eslint-disable complexity */
  buildhdToggle(player, controls, layers, media) {
    const t = this;
    const hdToggleText = mejs.Utils.isString(t.options.hdToggleText)
      ? t.options.hdToggleText
      : mejs.i18n.t('mejs.hd-toggle');
    player.qualities = [];

    player.sources = $(player.domNode).find('source');
    for (var i = 0; i < player.sources.length; i++) {
      var src = player.sources[i];
      for (var j = 0; j < player.options.hdToggleBetween.length; j++) {
        if (
          src.getAttribute('data-quality') === player.options.hdToggleBetween[j]
        ) {
          player.qualities[j] = src.getAttribute('src');
        }
      }
    }

    player.hdtoggleButton = document.createElement('div');
    player.hdtoggleButton.className =
      t.options.classPrefix +
      'button ' +
      t.options.classPrefix +
      'hd-toggle-button';
    player.hdtoggleButton.innerHTML = `<button type="button" aria-controls="${
      t.id
    }"
      title="${hdToggleText}">${player.options.hdToggleLabel}</button>`;

    player.hdtoggleButton.addEventListener('click', t.toggleQuality.bind(t));

    // Add control button to player
    t.addControlElement(player.hdtoggleButton, 'hdToggle');

    if (player.options.hdToggleOn && player.qualities[0] !== null) {
      player.hdtoggleButton.className += ' mejs__hdtoggle-on';
      player.switchStream(player.qualities[0]);
    } else if (player.qualities[1] !== null) {
      player.switchStream(player.qualities[1]);
    } else {
      // Fixme: Ideally we should display this message in a player overlay
      alert(
        'Did not find ' +
          hdToggleBetween[0] +
          ' and ' +
          hdToggleBetween[1] +
          ' streams'
      );
    }
  },
  /* eslint-enable complexity */

  /**
   * Feature destructor.
   *
   * Always has to be prefixed with `clean` and the name that was used in MepDefaults.features list
   * @param {MediaElementPlayer} player
   * @param {HTMLElement} controls
   * @param {HTMLElement} layers
   * @param {HTMLElement} media
   */
  cleanhdToggle(player, controls, layers, media) {
    if (player && player.hdtoggleButton) {
      player.hdtoggleButton.remove();
    }
  },

  /**
   * Toggle HD button state and change media source
   */
  toggleQuality: function() {
    let $btn = $(this.hdtoggleButton);
    if ($btn.hasClass('mejs__hdtoggle-on')) {
      $btn.removeClass('mejs__hdtoggle-on');
      this.switchStream(this.qualities[1]);
    } else {
      $btn.addClass('mejs__hdtoggle-on');
      this.switchStream(this.qualities[0]);
    }
  },

  /**
   * Switch the currently playing file
   *
   * @param src new media SRC
   */
  switchStream: function(src) {
    let media = this.media;

    // Do nothing if asked to to the same thing
    if (media.currentSrc !== src) {
      let currentTime = media.currentTime;
      let paused = media.paused;

      media.pause();
      media.setSrc(src);
      media.addEventListener(
        'loadedmetadata',
        function(e) {
          // Continue playing where we stopped
          media.currentTime = currentTime;
        },
        true
      );

      var canPlayAfterSourceSwitchHandler = function(e) {
        if (!paused) {
          media.play();
        }
        media.removeEventListener(
          'canplay',
          canPlayAfterSourceSwitchHandler,
          true
        );
      };
      media.addEventListener('canplay', canPlayAfterSourceSwitchHandler, true);

      media.load();
    }
  }
});
