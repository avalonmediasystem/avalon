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
 * Playlist Items plugin
 *
 * A custom Avalon MediaElement 4 plugin for handling playlist item interactions
 */

// Feature configuration
Object.assign(mejs.MepDefaults, {
  // Any variable that can be configured by the end user belongs here.
  // Make sure is unique by checking API and Configuration file.
  // Add comments about the nature of each of these variables.
});

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
  buildplaylistItems(player, controls, layers, media) {
    // This allows us to access options and other useful elements already set.
    // Adding variables to the object is a good idea if you plan to reuse
    // those variables in further operations.
    const t = this;
    let playlistItemsObj = t.playlistItemsObj;

    // Helper classes
    playlistItemsObj.mejsUtility = new MEJSUtility();
    playlistItemsObj.mejsMarkersHelper = new MEJSMarkersHelper();
    playlistItemsObj.mejsTimeRailHelper = new MEJSTimeRailHelper();

    playlistItemsObj.player = player;
    playlistItemsObj.mediaElement = media;
    // Track the number of MEJS 'timeupdate' events which fire after the end time of a playlist item
    playlistItemsObj.endTimeCount = 0;

    // Show/hide add marker button on player
    playlistItemsObj.mejsMarkersHelper.showHideAddMarkerButton();

    // Click listeners
    playlistItemsObj.addSidebarListeners();
    playlistItemsObj.addRelatedItemListeners();
    playlistItemsObj.mejsMarkersHelper.addMarkersTableListeners();
    playlistItemsObj.addMarkerClickListener();

    // Turn off autoplay on seek
    playlistItemsObj.mejsTimeRailHelper
      .getTimeRail()
      .addEventListener('click', playlistItemsObj.handleUserSeeking.bind(this));
    let scrubberRail = $(
      playlistItemsObj.player.trackScrubberObj.scrubberEl
    ).find('.track-mejs-time-total')[0];
    scrubberRail.addEventListener(
      'click',
      playlistItemsObj.handleUserSeeking.bind(this)
    );

    // Handle continuous MEJS time update event
    media.addEventListener(
      'timeupdate',
      playlistItemsObj.handleTimeUpdate.bind(this)
    );

    // Set current playing item in this class context
    playlistItemsObj.setCurrentItemInternally();

    // Handle canplay event, which defines a 'state' needed before we can call other setup functions
    media.addEventListener(
      'canplay',
      playlistItemsObj.handleCanPlay.bind(playlistItemsObj)
    );

    if (playlistItemsObj.mejsUtility.isMobile()) {
      playlistItemsObj.handleCanPlayMobile();
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
  cleanplaylistItems(player, controls, layers, media) {
    // Remove click listener on playlist items
    $('#right-column')
      .find('.side-playlist')
      .off('click');
  },

  // Other optional public methods (all documented according to JSDoc specifications)

  /**
   * The 'playlistItemsObj' object acts as a namespacer for this plugin's
   * specific variables and methods, so as not to pollute global or MEJS scope.
   * @type {Object}
   */
  playlistItemsObj: {
    /**
     * Custom event listener for clicks on markers (which are currently handled
     * in app/assets/javascripts/media_player_wrapper/mejs4_helper_markers.es6)
     *
     * This function determines whether marker time clicked is past playlist item end time,
     * and takes action if so.
     * @function addMarkerClickListener
     * @return {void}
     */
    addMarkerClickListener() {
      const t = this;
      // This custom event is fired when a marker is clicked
      // in app/assets/javascripts/media_player_wrapper/mejs4_helper_markers.es6.
      document.addEventListener('markerClicked', e => {
        const markerTime = e.detail.offset;
        if (markerTime > t.startEndTimes.end) {
          t.turnOffAutoplay();
          t.seekPastEnd = true;
        }
      });
    },

    /**
     * Add click listeners for playlist item links
     * @function addRelatedItemListeners
     * @return {void}
     */
    addRelatedItemListeners() {
      // Handle click on entire RelatedItems area
      // Filter only <a> element clicks; disregard all others
      if (this.$relatedItems.length > 0) {
        this.$relatedItems.on('click', e => {
          if (e.target.nodeName === 'A') {
            e.preventDefault();
            // find correct playlist item in sidebar and click it.
            let playlistId = e.target.dataset.playlistId;
            let playlistItemId = e.target.dataset.playlistItemId;
            let related = this.$sidePlaylist.find(
              `a[data-playlist-id="${playlistId}"][data-playlist-item-id="${playlistItemId}"]`
            );
            related.click();
          }
        });
      }
    },

    /**
     * Add click listener for the playlist items sidebar
     * @function addSidebarListeners
     * @return {void}
     */
    addSidebarListeners() {
      // Handle click on entire Playlists right column area
      // Filter only <a> element clicks; disregard all others
      if (this.$sidePlaylist.length > 0) {
        this.$sidePlaylist.on('click', e => {
          if (e.target.nodeName === 'A') {
            e.preventDefault();
            this.handleClick(e.target);
          }
        });
      }
    },

    /**
     * Analyze the new playlist item and determine how to proceed...
     * @function analyzeNewItemSource
     * @param  {HTMLElement} el <a> anchor element of the new playlist item being processed
     * @param {Boolean} isEnded
     * @return {void}
     */
    analyzeNewItemSource(el, isEnded) {
      const playlistId = +el.dataset.playlistId;
      const playlistItemId = el.dataset.playlistItemId;
      const playlistItemT = [
        el.dataset.clipStartTime / 1000,
        el.dataset.clipEndTime / 1000
      ];
      const isSameMediaFile =
      this.$nowPlayingLi.find('a').data('masterFileId') === el.dataset.masterFileId;

      // Update right column playlist items list
      this.updatePlaylistItemsList(el);

      // Show/hide add marker button on player
      this.mejsMarkersHelper.showHideAddMarkerButton();

      // Update markers in time rail
      this.mejsMarkersHelper.updateVisualMarkers();

      // Same media file?
      if (isSameMediaFile) {
        // Set the endTimeCount back to 0
        this.endTimeCount = 0;
        this.setupNextItem();
      } else {
        // Need a new Mediaelement player and media file
        const id = el.dataset.masterFileId;
        const url = `/media_objects/${el.dataset.mediaObjectId}/section/${id}`;

        // Update mejs4AvalonPlayer.playlistItem with ids here
        mejs4AvalonPlayer.playlistItem = Object.assign(
          {},
          mejs4AvalonPlayer.playlistItem,
          { id: playlistItemId, playlist_id: playlistId, position: null }
        );

        // Set now playing item in playlist items
        this.setCurrentItemInternally();

        // Get new data and create new player instance
        mejs4AvalonPlayer.getNewStreamAjax(url, isEnded, playlistItemT);

        // Use switchItemHelper only when previous item is ended 
        // and both current and prev items are video
        const prevItemIsVideo = this.$nowPlayingLi.prev('li').data('isVideo');
        const currentItemIsVideo = this.$nowPlayingLi.data('isVideo');
        if(isEnded && prevItemIsVideo && currentItemIsVideo) {
          this.switchItemHelper();
        }
      }

      // Rebuild playlist info panels
      this.rebuildPlaylistInfoPanels(playlistId, playlistItemId);
    },

    /**
     * Helper function when re-initializing the player instance when advancing from a
     * playlist item to next when the playlist item ends
     * @function switchItemHelper
     * @returns {void}
     */
    switchItemHelper() {
      this.mejsMarkersHelper.updateVisualMarkers();

      // Build markers and timerail highlight
      let promises = [];
      const playlistItem = mejs4AvalonPlayer.playlistItem;
      const playlistIds = playlistItem
      ? [playlistItem.playlist_id, playlistItem.id]
      : [];
      promises.push(this.mejsMarkersHelper.getMarkers(...playlistIds));
      Promise.all(promises)
        .then(() => {
          this.mejsMarkersHelper.updateVisualMarkers();
          mejs4AvalonPlayer.highlightTimeRail([this.startEndTimes.start, this.startEndTimes.end]);
        })
        .catch(error => {
          console.log('Promise rejection error');
        });

      this.player.buildmarkers(this.player, this.player.controls, null, this.mediaElement);
    },

    /**
     * Helper variable to track the number of times the playlist item's end time handler function has been called
     * @type {Number}
     */
    endTimeCount: 0,

    /**
     * Returns the next playlist list (<li>) item in sidebar
     * @function getNextItem
     * @return {Object} jQuery object
     */
    getNextItem() {
      let nextItem = this.$nowPlayingLi.next('li');
      // When next item is not a valid playlist item (e.g. from a deleted item) get the item after that
      if(nextItem[0] && nextItem[0].className !== 'queue') {
        nextItem = nextItem.next('li');
      }
      return nextItem;
    },

    /**
     * Go to the playlist item's start time in player, and play file if configured to autoplay
     * @function goToPlaylistItemStartTime
     * @return {void}
     */
    goToPlaylistItemStartTime() {
      this.player.setCurrentTime(this.startEndTimes.start);
      if (this.isAutoplay() && !this.player.avalonWrapper.isFirstLoad) {
        this.player.play();
      }
      this.player.avalonWrapper.isFirstLoad = false;
    },

    /**
     * Handle Mediaelement 'canplay' event in this plugin file.
     * When 'canplay' fires, then we have the information on the player we need to execute
     * the internal functions defined below.
     * @return {void}
     */
    handleCanPlay() {
      const t = this;
      const currentPlaylistIds = t.mejsMarkersHelper.getCurrentPlaylistIds();

      t.rebuildPlaylistInfoPanels(
        currentPlaylistIds['playlistId'],
        currentPlaylistIds['playlistItemId']
      );
      t.goToPlaylistItemStartTime();
    },

    /**
     * Helper function for mobile/iOS as the 'canplay' event never reaches this plugin for some reason.
     * @function handleCanPlayMobile
     * @return {void}
     */
    handleCanPlayMobile() {
      const t = this;

      // Custom poller function which checks if currentPlaylistIds are ready yet, every 1 second until they are.
      const poller = () => {
        setTimeout(() => {
          const currentPlaylistIds = t.mejsMarkersHelper.getCurrentPlaylistIds();
          if (!currentPlaylistIds) {
            poller();
          } else {
            t.handleCanPlay();
          }
        }, 1000);
      };
      poller();
    },

    /**
     * Handle click event on a playlist item in the right sidebar
     * @function handleClick
     * @param  {HTMLElement} el <a> html element of playlist item
     * @return {void}
     */
    handleClick(el) {
      this.turnOffAutoplay();
      this.mejsUtility.showControlsBriefly(this.player);

      // Clicked same item. Play from item start time and return
      if (this.isSamePlaylistItem(el)) {
        this.player.setCurrentTime(this.startEndTimes.start);
        return;
      }

      this.analyzeNewItemSource(el, false);
    },

    /**
     * Playlist item time range has ended. Handle next steps here.
     * @function handleRangeEndTimeReached
     * @return {void}
     */
    handleRangeEndTimeReached() {
      const t = this;
      const $nextItem = t.getNextItem();

      t.endTimeCount++;
      t.player.pause();

      // Return playlist head to item's start time
      if ($nextItem.length === 0 || !t.isAutoplay()) {
        t.player.setCurrentTime(t.startEndTimes.start);
        t.endTimeCount = 0;
        return;
      }

      // Autoplay is 'On'
      if (t.isAutoplay()) {
        const el = $nextItem.find('a')[0];
        t.analyzeNewItemSource(el, true);
      }
    },

    /**
     * Handle MEJS's continuous time event
     * @function handleTimeUpdate
     * @return {void}
     */
    handleTimeUpdate() {
      const t = this;
      const plo = t.playlistItemsObj || t;
      const currentTime = plo.player.getCurrentTime();
      const isEnded = plo.isItemEnded(currentTime);

      // The player currentTime is less than item end time, so revert to regular behavior
      // of playing through time ranges
      if (currentTime < plo.startEndTimes.end) {
        plo.seekPastEnd = false;
      }

      // Do nothing, current time is within playlist item start / end range
      if (plo.isCurrentTimeInRange(currentTime)) {
        return;
      }

      // Playlist item's end time is reached
      if (isEnded && plo.endTimeCount < 1 && !plo.seekPastEnd) {
        plo.handleRangeEndTimeReached();
        return;
      }
    },

    /**
     * Handle user's manual seeking
     * @function handleUserSeeking
     * @param {MouseEvent} e Event emitted from the 'seeking'
     * @return {void}
     */
    handleUserSeeking(e) {
      const plo = this.playlistItemsObj;
      const currentTime = plo.player.getCurrentTime();

      // Always turn off Autoplay when user starts seeking around
      plo.turnOffAutoplay();
      // User seeked past the item end point
      if (plo.isItemEnded(currentTime)) {
        plo.seekPastEnd = true;
      }
    },

    /**
     * Does the DOM reflect that Autoplay is 'On'? (Note: DOM checkbox value is the source of truth)
     * @function isAutoplay
     * @return {Boolean} [description]
     */
    isAutoplay() {
      return !$('input[name="autoadvance"]')
        .parent('.toggle')
        .hasClass('off');
    },

    /**
     * Helper function: is the player's current time within the playlist items start / end time range?
     * Note the 'threshold' helper variable, and see description below for why it's needed.
     * @function isCurrentTimeInRange
     * @param  {number}  currentTime Current time of Mediaelement player
     * @return {Boolean}
     */
    isCurrentTimeInRange(currentTime) {
      const t = this;
      const currentTimeAdjusted = currentTime + t.threshold;
      const startEndTimes = t.startEndTimes;
      return currentTime >= startEndTimes.start && !t.isItemEnded(currentTime);
    },

    /**
     * Helper function: is the argument element passed into this function the current playlist item?
     * @function isSamePlaylistItem
     * @param  {HTMLElement}  el
     * @return {Boolean}
     */
    isSamePlaylistItem(el) {
      return (
        $(el).data('playlistItemId') ===
        this.$nowPlayingLi.data('playlistItemId')
      );
    },

    /**
     * Helper function: has the playlist item's time time range ended?
     * @function isItemEnded
     * @param  {number}  currentTime Current time of Mediaelement player
     * @return {Boolean}
     */
    isItemEnded(currentTime) {
      const t = this;
      return t.startEndTimes.end - currentTime < t.threshold;
    },

    /**
     * Reference to jQuery variable for the currently playing <li> in sidebar
     * @type {Object}
     */
    $nowPlayingLi: null,

    /**
     * Re-build playlist item info page panel HTML sections
     * @function rebuildPlaylistInfoPanels
     * @param playlistId
     * @param playlistItemId,
     * @return {void}
     */
    rebuildPlaylistInfoPanels(playlistId, playlistItemId) {
      const t = this;

      // Rebuild playlistItem heading
      t.rebuildHeading(playlistId, playlistItemId);
      // Rebuild markers table
      t.mejsMarkersHelper.rebuildMarkers();
      // Rebuild source item details panel section
      t.rebuildPanelMarkup(playlistId, playlistItemId, 'source_details');
      // Rebuild the related items panel section
      t.rebuildPanelMarkup(playlistId, playlistItemId, 'related_items');
    },

    /**
     * Re-build item details page panel HTML sections
     * @function rebuildHeading
     * @param playlistId
     * @param playlistItemId,
     * @return {void}
     */
    rebuildHeading(playlistId, playlistItemId) {
      const $nowPlaying = this.$sidePlaylist.find(
        'a[data-playlist-id=' +
          playlistId +
          '][data-playlist-item-id=' +
          playlistItemId +
          ']'
      );
      const duration = $nowPlaying.next('span').text();
      const $headingTitle = $('#heading0 h4 span:first');
      $headingTitle.text($.trim($nowPlaying.text()));
      $headingTitle.next().text('[' + $.trim(duration) + ']');
      const $headingComment = $('#heading0 h4').next('div');
      $headingComment.text($nowPlaying.data('clipComment'));
    },

    /**
     * Re-build item details page panel HTML sections
     * @function rebuildPanelMarkup
     * @param playlistId
     * @param playlistItemId,
     * @param panel String for endpoint title which correspondes to Playlist Items page panel section id
     * @return {void}
     */
    rebuildPanelMarkup(playlistId, playlistItemId, panel) {
      const t = this;

      // Add loading spinner
      t.mejsMarkersHelper.spinnerToggle(panel, true);

      // Grab new html to use
      t.mejsMarkersHelper
        .ajaxPlaylistItemsHTML(playlistId, playlistItemId, panel)
        .then(response => {
          // Insert the fresh HTML content
          $('#' + panel).html(response);
          // Hide the entire panel if new content is blank
          if (response === '') {
            $('#' + panel + '_section').collapse('hide');
            $('#' + panel + '_heading').hide();
          } else {
            $('#' + panel + '_heading').show();
          }
          t.mejsMarkersHelper.spinnerToggle(panel);
        })
        .catch(err => {
          console.log(err);
          t.mejsMarkersHelper.spinnerToggle(panel);
        });
    },

    /**
     * Helper jQuery object reference for related item list element. Used multile times in this class.
     * @type {Object}
     */
    $relatedItems: $('#related_items_section') || null,

    /**
     * Helper variable specifying whether the user has clicked in the time rail past the playlist item end time.
     * @type {Boolean}
     */
    seekPastEnd: false,

    /**
     * Set the now playing item helper variable, and update start end times for
     * current playing item
     * @function setCurrentItemInternally
     * @return {void}
     */
    setCurrentItemInternally() {
      const t = this;
      // Set current playing item
      t.$nowPlayingLi = t.$sidePlaylist.find('li.now_playing');
      t.updateStartEndTimes(t.$nowPlayingLi.find('a').data());
    },

    /**
     * Wrapper function for playing next item in the list
     * @function setupNextItem
     * @return {void}
     */
    setupNextItem() {
      this.setCurrentItemInternally();
      this.player.setCurrentTime(this.startEndTimes.start);
      mejs4AvalonPlayer.highlightTimeRail([
        this.startEndTimes.start,
        this.startEndTimes.end
      ]);
      if (this.isAutoplay()) {
        this.player.play();
      }
    },

    /**
     * Helper jQuery object reference for side playlist element. Used multile times in this class.
     * @type {Object}
     */
    $sidePlaylist: $('#right-column').find('.side-playlist') || null,

    /**
     * Helper object initializer to store current playlist item's start and stop times
     * @type {Object}
     */
    startEndTimes: {
      start: null,
      end: null
    },

    threshold: 0.25,

    /**
     * Turn off Autoplay (auto advancing to next item)
     * @function turnOffAutoplay
     * @return {void}
     */
    turnOffAutoplay() {
      $('input[name="autoadvance"]')
        .prop('checked', false)
        .change();
    },

    /**
     * Update playlist item start and end times
     * @function updateStartEndTimes
     * @param  {Object} dataSet HTML element "dataset" property
     * @return {void}
     */
    updateStartEndTimes(dataSet) {
      this.startEndTimes.start = parseInt(dataSet.clipStartTime, 10) / 1000;
      this.startEndTimes.end = parseInt(dataSet.clipEndTime, 10) / 1000;
    },

    /**
     * Update styles on the playlist items list in right sidebar
     * @function updatePlaylistItemsList
     * @param  {HTMLElement} el The <a> item HTML element which is the new item
     * @return {void}
     */
    updatePlaylistItemsList(el) {
      const liItems = this.$sidePlaylist[0].getElementsByTagName('li');
      let array = [...liItems];
      let clickedEl = el.parentNode;

      // Loop through all children list items
      array.forEach(li => {
        // Remove styles
        li.classList.remove('now_playing');
        li.classList.remove('queue');
        // Conditionally add styles to the item clicked
        if (li === clickedEl) {
          li.classList.add('now_playing');
        } else {
          li.classList.add('queue');
        }
      });
    }
  }
});
