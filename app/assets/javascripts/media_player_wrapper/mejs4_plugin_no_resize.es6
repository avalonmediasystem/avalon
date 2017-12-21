'use strict';

/**
 * This "feature" stops the global resizing when player is embedded in iframe
 */

// Feature configuration
Object.assign(mejs.MepDefaults, {});

Object.assign(MediaElementPlayer.prototype, {
  /**
   * Feature constructor.
   *
   * Always has to be prefixed with `build` and the name that will be used in MepDefaults.features list
   * @param {MediaElementPlayer} player
   * @param {HTMLElement} controls
   * @param {HTMLElement} layers
   * @param {HTMLElement} media
   */
  buildnoResize(player, controls, layers, media) {
    const t = player;
    t.globalResizeCallback = () => {
      // don't resize inside a frame/iframe
      if (window.top === window.self) {
        // don't resize for fullscreen mode
        if (!(t.isFullScreen || (HAS_TRUE_NATIVE_FULLSCREEN && document.webkitIsFullScreen))) {
          t.setPlayerSize(t.width, t.height);
        }
      }
      // always adjust controls
      t.setControlsSize();
    }
  },

  /**
   * Feature destructor. Restore original handler
   *
   * Always has to be prefixed with `clean` and the name that was used in MepDefaults.features list
   * @param {MediaElementPlayer} player
   * @param {HTMLElement} controls
   * @param {HTMLElement} layers
   * @param {HTMLElement} media
   */
  cleannoResize(player, controls, layers, media) {
    const t = player;
    t.globalResizeCallback = () => {
      // don't resize for fullscreen mode
      if (!(t.isFullScreen || (HAS_TRUE_NATIVE_FULLSCREEN && document.webkitIsFullScreen))) {
        t.setPlayerSize(t.width, t.height);
      }
      // always adjust controls
      t.setControlsSize();
    }
  }
});
