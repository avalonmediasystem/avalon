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

    playlistItemsObj.mejsUtility = new MEJSUtility();
    playlistItemsObj.mejsMarkersHelper = new MEJSMarkersHelper();
    playlistItemsObj.player = player;
    playlistItemsObj.currentStreamInfo = mejs4AvalonPlayer.currentStreamInfo;

    // Click listeners
    playlistItemsObj.addSidebarListeners();
    playlistItemsObj.addRelatedItemListeners();
    playlistItemsObj.mejsMarkersHelper.addMarkersTableListeners();

    // Handle continuous MEJS time update event
    media.addEventListener(
      'timeupdate',
      playlistItemsObj.handleTimeUpdate.bind(this)
    );
    // Set current playing item in this class context
    playlistItemsObj.setCurrentItemInternally();
    // Handle canplay event, start the player at the playlist item start time
    media.addEventListener(
      'canplay',
      playlistItemsObj.goToPlaylistItemStartTime.bind(playlistItemsObj)
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
     * Add click listeners forplaylist item links
     * @function addRelatedItemListeners
     * @return {void}
     */
    addRelatedItemListeners() {
      // Handle click on entire RelatedItems area
      // Filter only <a> element clicks; disregard all others
      if (this.$relatedItems.length > 0) {
        this.$relatedItems.on('click', (e) => {
          if (e.target.nodeName === 'A') {
            e.preventDefault()
            // find correct playlist item in sidebar and click it.
            let playlistId  = e.target.dataset.playlistId
            let playlistItemId = e.target.dataset.playlistItemId
            let related = this.$sidePlaylist.find('a[data-playlist-id='+playlistId+'][data-playlist-item-id='+playlistItemId+']')
            related.click()
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
            e.preventDefault()
            this.handleClick(e.target);
          }
        });
      }
    },

    /**
     * Analyze the new playlist item and determine how to proceed...
     * @param  {HTMLElement} el <a> anchor element of the new playlist item being processed
     * @return {void}
     */
    analyzeNewItemSource(el) {
      const playlistId = +el.dataset.playlistId;
      const playlistItemId = el.dataset.playlistItemId;
      const playlistItemT = [
        el.dataset.clipStartTime / 1000,
        el.dataset.clipEndTime / 1000
      ];

      // Show spinner
      this.mejsMarkersHelper.spinnerToggle(true);

      // Get new markers
      this.mejsMarkersHelper
        .getMarkers(playlistId, playlistItemId)
        .then(response => {
          const markers = response;

          // Update markers in time rail, and update right column playlist items list
          this.mejsMarkersHelper.updateVisualMarkers(markers);
          this.updatePlaylistItemsList(el);

          // Rebuild markers table
          this.mejsMarkersHelper.rebuildMarkersTable();
          // Rebuild source item details panel section
          this.rebuildPanelMarkup(playlistId, playlistItemId, 'metadata');
          // Rebuild the related items panel section
          this.rebuildPanelMarkup(playlistId, playlistItemId, 'related_items');

          // Same media file?
          if (this.currentStreamInfo.id === el.dataset.masterFileId) {
            this.setupNextItem();
          } else {
            // Need a new Mediaelement player and media file
            const id = el.dataset.masterFileId;
            const url = `/media_objects/${
              el.dataset.mediaObjectId
            }/section/${id}`;

            // Update mejs4AvalonPlayer.playlistItem with ids here
            mejs4AvalonPlayer.playlistItem = Object.assign(
              {},
              mejs4AvalonPlayer.playlistItem,
              { id: playlistItemId, playlist_id: playlistId, position: null }
            );

            // Get new data and create new player instance
            mejs4AvalonPlayer.getNewStreamAjax(id, url, playlistItemT);
          }
        });
    },

    currentStreamInfo: null,

    getNextItem() {
      return this.$nowPlayingLi.next('li');
    },

    /**
     * Go to the playlist item's start time in player, and play file if configured to autoplay
     * @function goToPlaylistItemStartTime
     * @return {void}
     */
    goToPlaylistItemStartTime() {
      this.player.setCurrentTime(this.startEndTimes.start);
      if (this.isAutoplay()) {
        this.player.play();
      }
    },

    /**
     * Handle click event on a playlist item in the right sidebar
     * @function handleClick
     * @param  {HTMLElement} el <a> html element of playlist item
     * @return {void}
     */
    handleClick(el) {
      // Clicked same item. Play from item start time and return
      if (this.isSamePlaylistItem(el)) {
        this.player.setCurrentTime(this.startEndTimes.start);
        return;
      }

      this.analyzeNewItemSource(el);
    },

    /**
     * Playlist item time range has ended. Handle next steps here.
     * @return {[type]} [description]
     */
    handleRangeEndTimeReached() {
      const t = this;
      const $nextItem = t.getNextItem();

      t.player.pause();
      if ($nextItem.length > 0) {
        const el = $nextItem.find('a')[0];
        t.analyzeNewItemSource(el);
      }
    },

    /**
     * Handle MEJS's continuous time event
     * @function handleTimeUpdate
     * @return {void}
     */
    handleTimeUpdate() {
      const t = this;
      const playlistItemsObj = t.playlistItemsObj;
      const currentTime = playlistItemsObj.player.getCurrentTime();

      // Current time is within range of playlist item's start / end times
      if (
        currentTime >= playlistItemsObj.startEndTimes.start &&
        currentTime < playlistItemsObj.startEndTimes.end
      ) {
        return;
      }

      // Playlist item's end time is reached
      if (playlistItemsObj.itemEnded()) {
        playlistItemsObj.handleRangeEndTimeReached();
        return;
      }
    },

    isAutoplay() {
      return !$('input[name="autoadvance"]')
        .parent('.toggle')
        .hasClass('off');
    },

    isSamePlaylistItem(el) {
      return $(el).data('playlistItemId') === this.$nowPlayingLi.data('playlistItemId');
    },

    itemEnded() {
      return this.player.getCurrentTime() > this.startEndTimes.end;
    },

    $nowPlayingLi: null,

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

      // Grab new html to use
      t.mejsMarkersHelper
        .ajaxPlaylistItemsHTML(playlistId, playlistItemId, panel)
        .then(response => {
          // Insert the fresh HTML content
          $('#' + panel).replaceWith(response);
          // Hide the entire panel if new content is blank
          if (response === '') {
            $('#' + panel + '_section').collapse('hide')
            $('#' + panel + '_heading').hide()
          } else {
            $('#' + panel + '_heading').show()
          }
        })
        .catch(err => {
          console.log(err);
        });
    },

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
     * Helper jQuery object reference for related item list element. Used multile times in this class.
     * @type {Object}
     */
    $relatedItems: $('#related_items_section') || null,

    /**
     * Helper object initializer to store current playlist item's start and stop times
     * @type {Object}
     */
    startEndTimes: {
      start: null,
      end: null
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
      const arrowNode = document.createElement('i');

      arrowNode.className = `fa fa-arrow-circle-right`;

      // Loop through all children list items
      array.forEach(li => {
        const children = [...li.children];
        let arrow = children.find(e => e.nodeName === 'I');
        // Remove styles
        li.classList.remove('now_playing');
        li.classList.remove('queue');
        if (arrow) {
          li.removeChild(arrow);
        }
        // Conditionally add styles to the item clicked
        if (li === clickedEl) {
          li.insertBefore(arrowNode, el);
          li.classList.add('now_playing');
        } else {
          li.classList.add('queue');
        }
      });
    }
  }
});
