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
 * Track Scrubber plugin
 *
 * A custom Avalon MediaElement 4 plugin for displaying a track section in greater visual detail
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
  buildtrackScrubber(player, controls, layers, media) {
    // This allows us to access options and other useful elements already set.
    // Adding variables to the object is a good idea if you plan to reuse
    // those variables in further operations.
    const t = this;
    const addTitle = 'Toggle Track Scrubber';
    let trackScrubberObj = t.trackScrubberObj;

    // Make player instance available outside of this method
    trackScrubberObj.player = player;

    // Create control button element
    player.trackScrubberButton = document.createElement('div');
    player.trackScrubberButton.className =
      t.options.classPrefix +
      'button ' +
      t.options.classPrefix +
      'track-scrubber-button';
    player.trackScrubberButton.innerHTML =
      '<button type="button" aria-controls="' +
      t.id +
      '" title="' +
      addTitle +
      '" aria-label="' +
      addTitle +
      '" tabindex="0">' +
      addTitle +
      '</button>';

    // Add control button to player
    t.addControlElement(player.trackScrubberButton, 'trackScrubber');

    trackScrubberObj.addScrubberToDOM();
    trackScrubberObj.addEventListeners();

    // Need the 'canplay' event first before we can start listening to 'timeupdate' event
    media.addEventListener('canplay', e => {
      trackScrubberObj.handleCanPlay(media);
    });

    // Set up click listener for the control button
    player.trackScrubberButton.addEventListener(
      'click',
      trackScrubberObj.handleControlClick.bind(t)
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
  cleantrackScrubber(player, controls, layers, media) {
    const t = this;
    const scrubberEl = t.trackScrubberObj.scrubberEl;
    scrubberEl.parentNode.removeChild(scrubberEl);

    // Remove this helper object to make sure we get fresh data next time the plugin file loads
    delete t.trackScrubberObj.trackdata;
  },

  // Other optional public methods (all documented according to JSDoc specifications)

  /**
   * The 'trackScrubberObj' object acts as a namespacer for this plugin's
   * specific variables and methods, so as not to pollute global or MEJS scope.
   * @type {Object}
   */
  trackScrubberObj: {
    /**
     * Add specific event listeners for this plugin
     * @function addEventListeners
     * @return {void}
     */
    addEventListeners: function() {
      // Resize event listener
      this.player.globalBind('resize', () => {
        this.resizeTrackScrubber();
      });
    },

    /**
     * Create track scrubber markup and add it to the DOM
     * @function addScrubberToDOM
     * @return {void}
     */
    addScrubberToDOM: function() {
      const referenceNode = document.getElementById('content');
      let newNode = document.createElement('div');
      const html = `<div class="mejs-time track-mejs-currenttime-container">
                    <span class="track-mejs-currenttime">00:00</span>
                  </div>
                  <div class="track-mejs-time-rail">
                    <span class="track-mejs-time-total">
                      <span class="track-mejs-time-current"></span>
                      <span class="track-mejs-time-handle"></span>
                      <span class="track-mejs-time-float" style="display: none;">
                        <span class="track-mejs-time-float-current">00:00</span>
                        <span class="track-mejs-time-float-corner"></span>
                      </span>
                    </span>
                  </div>
                  <div class="mejs-time track-mejs-duration-container">
                    <span class="track-mejs-duration">00:00</span>
                  </div>`;
      newNode.id = 'track_scrubber';
      newNode.className = 'track_scrubber hidden';
      newNode.innerHTML = html;
      referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
      // Save the reference for future use
      this.scrubberEl = document.getElementById('track_scrubber');
    },

    /**
     * Handle control button click
     * @function handleControlClick
     * @param  {MouseEvent} e Event generated when control button clicked
     * @return {void}
     */
    handleControlClick: function(e) {
      if (this.trackScrubberObj.player.isFullScreen) {
        this.trackScrubberObj.player.exitFullScreen();
      }
      this.trackScrubberObj.showTrackScrubber(
        this.trackScrubberObj.scrubberEl.classList.contains('hidden')
      );
    },

    /**
     * Handle Mediaelements 'canplay' event in this plugin
     * @function handleCanPlay
     * @param  {Object} media media object provided to the plugin
     * @return {void}
     */
    handleCanPlay: function(media) {
      media.addEventListener('timeupdate', () => {
        this.handleTimeUpdate();
      });
    },

    /**
     * Handle Mediaelement 'timeupdate' event in this plugin
     * @function handleTimeUpdate
     * @return {void}
     */
    handleTimeUpdate: function() {
      if (!this.player || this.player === null) {
        return;
      }
      const currentTime = this.player.getCurrentTime();
      this.updateTrackScrubberProgressBar(currentTime);
    },

    /**
     * Initialize the track scrubber setup.  This could be for the entire track, or it could be
     * just for a section (segment) of time within the track.
     * @function initializeTrackScrubber
     * @param  {number} trackstart  Start time of the scrubber in seconds
     * @param  {number} trackend    End time of the scrubber in seconds
     * @param  {Object} stream_info Current stream object
     * @return {Object} HTML event binder
     */
    /* eslint-disable max-statements, complexity */
    initializeTrackScrubber: function(trackstart, trackend, stream_info) {
      const t = this;

      if (!stream_info.hasOwnProperty('t')) {
        return;
      }
      // Determine whether we're on a touch device or not
      const hasTouch = this.isTouchDevice();
      const duration = stream_info.duration;
      const trackduration = trackend - trackstart;
      let $currentTime = $('.track-mejs-currenttime');
      $currentTime.text(
        mejs.Utils.secondsToTimeCode(
          Math.max(0, t.player.getCurrentTime() - trackstart),
          false
        )
      );

      t.trackdata = {};
      t.trackdata['starttime'] = trackstart;
      t.trackdata['endtime'] = trackend;
      t.trackdata['duration'] = duration;
      t.trackdata['trackduration'] = trackduration;

      let $duration = $('.track-mejs-duration');
      $duration.text(
        mejs.Utils.secondsToTimeCode(parseInt(trackduration, 10), false)
      );

      let start_percent = Math.max(
        0,
        Math.min(100, Math.round(100 * trackstart / duration))
      );
      let end_percent = Math.max(
        0,
        Math.min(100, Math.round(100 * trackend / duration))
      );
      let clip_span = $('<span />').addClass('mejs-time-clip');
      let trackbubble = $('<span class="mejs-time-clip">');
      trackbubble.css('left', start_percent + '%');
      trackbubble.css('width', end_percent - start_percent + '%');

      $('.mejs-time-clip').remove();

      if (!(start_percent === 0 && end_percent === 100)) {
        $('.mejs-time-total').append(trackbubble);
      }

      let total = $('.track-mejs-time-total');
      let current = $('.track-mejs-time-current');
      let handle = $('.track-mejs-time-handle');
      let $timefloat = $('.track-mejs-time-float');
      let timefloatcurrent = $('.track-mejs-time-float-current');
      let slider = $('.track-mejs-time-slider');
      let media = t.player.media;
      let mouseIsDown = false;
      let mouseIsOver = false;

      let handleMouseMove = function(e) {
        let offset = total.offset();
        let width = total.width();
        let percentage = 0;
        let newTime = 0;
        let pos = 0;
        let x;

        // mouse or touch position relative to the object
        if (e.originalEvent && e.originalEvent.changedTouches) {
          x = e.originalEvent.changedTouches[0].pageX;
        } else if (e.changedTouches) {
          // for Zepto
          x = e.changedTouches[0].pageX;
        } else {
          x = e.pageX;
        }

        if (media.duration) {
          if (x < offset.left) {
            x = offset.left;
          } else if (x > width + offset.left) {
            x = width + offset.left;
          }

          pos = x - offset.left;
          percentage = pos / width || 0;
          newTime =
            percentage <= 0.02 ? 0 : percentage * t.trackdata.trackduration;

          // seek to where the mouse is
          if (mouseIsDown && newTime !== media.currentTime) {
            media.setCurrentTime(newTime + parseFloat(t.trackdata.starttime));
          }
          // position floating time box
          if (!hasTouch) {
            $timefloat.css('left', pos);
            timefloatcurrent.html(mejs.Utils.secondsToTimeCode(newTime, false));
          }
        }
      };

      return total
        .bind('mousedown touchstart', e => {
          // only handle left clicks or touch
          if (e.which === 1 || e.which === 0) {
            mouseIsDown = true;
            handleMouseMove(e);
            t.player.globalBind('mousemove.dur touchmove.dur', e => {
              handleMouseMove(e);
            });
            t.player.globalBind('mouseup.dur touchend.dur', e => {
              mouseIsDown = false;
              $timefloat.hide();
              t.player.globalUnbind('.dur');
            });
          }
        })
        .bind('mouseenter', e => {
          mouseIsOver = true;
          t.player.globalBind('mousemove.dur', e => {
            handleMouseMove(e);
          });

          if (!hasTouch) {
            $timefloat.show();
          }
        })
        .bind('mouseleave', e => {
          mouseIsOver = false;
          if (!mouseIsDown) {
            t.player.globalUnbind('.dur');
            $('.track-mejs-time-float').hide();
          }
        });
    },
    /* eslint-enable max-statements, complexity */

    /**
     * Determine whether this is desktop or non-desktop
     * @function isTouchDevice
     * @return {boolean}
     */
    isTouchDevice: function() {
      const features = mejs.Features;

      return (
        features.isAndroid ||
        features.isStockAndroid ||
        features.isiOs ||
        features.isiPad ||
        features.isiPhone ||
        features.isiPod
      );
    },

    /**
     * Handle player resize events for the track scrubber
     * @function resizeTrackScrubber
     * @return {void}
     */
    resizeTrackScrubber: function() {
      let scrubberEl = this.scrubberEl;
      let $timeTotal = $(scrubberEl).find('.track-mejs-time-total');
      const totalWidth = scrubberEl.offsetWidth;
      const timeWidth = $(scrubberEl)
        .find('.track-mejs-currenttime-container')
        .outerWidth(true);
      const durationWidth = $(scrubberEl)
        .find('.track-mejs-duration-container')
        .outerWidth(true);
      const railWidth = totalWidth - timeWidth - durationWidth - 5;
      const totalTimeWidth =
        railWidth - ($timeTotal.outerWidth(true) - $timeTotal.width());

      // Set widths
      $('.track-mejs-time-rail').width(railWidth);
      $timeTotal.width(totalTimeWidth);
    },

    /**
     * Track scrubber DOM element reference
     * @type {HTMLElement}
     */
    scrubberEl: null,

    /**
     * Toggle display of the track scrubber DOM element
     * @function showTrackScrubber
     * @param  {boolean} show Does this method show the scrubber?
     * @return {void}
     */
    showTrackScrubber: function(show) {
      let scrubberEl = this.scrubberEl;

      if (show) {
        $('#content')
          .find('.mejs__track-scrubber-button')
          .addClass('track-scrubber-hide')
          .removeClass('track-scrubber-show');
        scrubberEl.classList.remove('hidden');
        this.resizeTrackScrubber();
      } else {
        $('#content')
          .find('.mejs__track-scrubber-button')
          .addClass('track-scrubber-show')
          .removeClass('track-scrubber-hide');
        scrubberEl.classList.add('hidden');
      }
    },

    /**
     * Update the track scrubber
     * @function updateTrackScrubberProgressBar
     * @param  {number} currentTime Current time (in seconds) of the MEJS player
     * @return {void}
     */
    updateTrackScrubberProgressBar: function(currentTime) {
      // Handle Safari which emits the timeupdate event really quickly
      if (!this.trackdata) {
        const currentStream = this.player.avalonWrapper.currentStreamInfo;
        this.initializeTrackScrubber(
          currentStream.t[0],
          currentStream.t[1],
          currentStream
        );
        return;
      }

      let trackoffset = currentTime - this.trackdata['starttime'];
      let trackpercent = Math.min(
        100,
        Math.max(0, 100 * trackoffset / this.trackdata['trackduration'])
      );

      $('.track-mejs-time-current').width(Math.round(trackpercent) + '%');
      $('.track-mejs-currenttime').text(
        mejs.Utils.secondsToTimeCode(trackoffset, false)
      );
    }
  }
});
