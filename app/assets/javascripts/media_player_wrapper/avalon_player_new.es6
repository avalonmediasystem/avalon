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

// declaring currentPlayer as global variable as it's used in multiple places outside the class
var currentPlayer;

/**
 * @class MEJSPlayer
 * @classdesc Wrapper for MediaElementPlayer interactions
 */
class MEJSPlayer {
  /**
   * Class constructor
   * @param  {Object} currentStreamInfo JSON of current media stream info
   * @param  {Object} customConfig      Custom configuration for player
   * @return {void}                   [description]
   */
  constructor(configObj) {
    this.mejsUtility = new MEJSUtility();
    this.mejsTimeRailHelper = new MEJSTimeRailHelper();
    this.mejsMarkersHelper = new MEJSMarkersHelper();
    this.mejsQualityHelper = new MEJSQualityHelper();
    this.localStorage = window.localStorage;

    // Unpack player configuration object for the new player.
    // This allows for variable params to be sent in.
    this.currentStreamInfo = configObj.currentStreamInfo || {};
    this.features = configObj.features || {};
    this.highlightRail = configObj.highlightRail;
    this.playlistItem = configObj.playlistItem || {};
    this.defaultQuality = configObj.defaultQuality || 'auto';

    // Tracks whether we're loading the page or just reloading player
    this.isFirstLoad = true;

    // Wrapper for MediaElement instance which interfaces with properties, events, etc.
    this.mediaElement = null;
    // Actual MediaElement instance
    this.player = null;
    // Add click listeners
    this.addSectionsClickListener();
    // audio or video file?
    this.mediaType = this.mejsUtility.getMediaType(
      this.currentStreamInfo.is_video
    );

    // Helper object when loading a new MEJS player instance (ie. a different media object source section link clicked)
    this.switchPlayerHelper = {
      active: false,
      data: {},
      paused: false
    };

    // Initialize switchPlayerHelper for mediafragment, if one exists
    if (this.currentStreamInfo.t && this.currentStreamInfo.t[0] > 0) {
      this.switchPlayerHelper.active = true;
      this.switchPlayerHelper.data = {
        fragmentbegin: this.currentStreamInfo.t[0],
        fragmentend: this.currentStreamInfo.t[1]
      };
      this.switchPlayerHelper.paused = true;
    }

    // Array of all current segments for media object
    this.segmentsMap = this.mejsUtility.createSegmentsMap(
      document.getElementById('accordion'),
      this.currentStreamInfo
    );
    // Holder for currently active segment DOM element 'id' attribute
    this.activeSegmentId = '';

    // Initialize the player
    this.initializePlayer();
  }

  /**
   * Add a listener for clicks on the 'Sections' links
   * @function addSectionsClickListener
   * @return {void}
   */
  addSectionsClickListener() {
    const $accordionEl = $('#accordion.media-show-page');
    if ($accordionEl.length > 0) {
      $accordionEl[0].addEventListener(
        'click',
        this.handleSectionClick.bind(this)
      );
    }
  }

  /**
   * Create the pieces for a new MediaElement player
   * @function createNewPlayer
   * @return {void}
   */
  createNewPlayer() {
    let itemScope = document.querySelector('[itemscope="itemscope"]');
    let node = this.mejsUtility.createHTML5MediaNode(
      this.mediaType,
      this.currentStreamInfo
    );

    // Mount new <audio> or <video> element to the DOM and initialize
    // a new MediaElement instance.
    itemScope.appendChild(node);
    this.initializePlayer();
  }

  /**
   * Emit custom event signaling Mediaelement new instance success callback has fired
   * @function emitSuccessEvent
   * @return {void}
   */
  emitSuccessEvent() {
    const event = new CustomEvent('mejs4handleSuccess');
    document.dispatchEvent(event);
  }

  /**
   * Make AJAX request for clicked item's stream data
   * @function getNewStreamAjax
   * @param  {string} id - id of master file id
   * @param {string} url Url to get stream data ie. /media_objects/xg94hp52v/section/bc386j20b
   * @param {Array} playlistItemT Array which contains playlist item clip start and end times.  This is sent in from playlist items plugin, when creating a new instance of the player.
   * @return {void}
   */
  getNewStreamAjax(id, url, playlistItemsT) {
    $('.media-show-page').removeClass('ready-to-play');
    $.ajax({
      url: url + '/stream',
      dataType: 'json',
      data: {
        content: id
      }
    })
      .done(response => {
        this.removePlayer();
        this.setContextVars(response, playlistItemsT);
        this.createNewPlayer();
        this.updateShareLinks();
      })
      .fail(error => {
        console.log('error', error);
      });
  }

  /**
   * Event handler for MediaElement's 'canplay' event
   * At this point can play, pause, set time on player instance
   * @function handleCanPlay
   * @return {void}
   */
  handleCanPlay() {
    this.mediaElement.removeEventListener('canplay');
    // Do we play a specified range of the media file?
    $('.media-show-page').addClass('ready-to-play');
    if (this.switchPlayerHelper.active) {
      this.playRange();
    }
  }

  /**
   * Event handler for MediaElement's 'volumechange' event
   * Save new volume to localStorage for initializing new players with that vol
   * @function handleVolumeChange
   * @return {void}
   */
  handleVolumeChange() {
    this.localStorage.setItem('startVolume', this.mediaElement.volume)
  }

  /**
   * Event handler for MediaElement's 'captionschange' event
   * Save new volume to localStorage for initializing new players with that vol
   * @function handleCaptionsChange
   * @return {void}
   */
  handleCaptionsChange() {
    let srclang = currentPlayer.selectedTrack === null ? '' : currentPlayer.selectedTrack.srclang;
    this.localStorage.setItem('captions', srclang)
  }

  /**
   * Handle Mediaelement's 'ended' event
   * @function handleEnded
   * @return {void}
   */
  handleEnded() {
    const t = this;

    // No sections content on this page, go no further
    if (!t.hasSections()) {
      return;
    }

    const $sections = $('#accordion').find('.panel-heading[data-section-id]');
    const sectionsIdArray = $sections.map((index, item) =>
      $(item).data('sectionId').toString()
    );
    const currentIdIndex = [...sectionsIdArray].indexOf(t.currentStreamInfo.id);

    // Another section exists; process it
    if (currentIdIndex > -1 && currentIdIndex + 1 < sectionsIdArray.length) {
      const sectionId = sectionsIdArray[currentIdIndex + 1];
      const mediaObjectId = $('#accordion')
        .find(`.panel-heading[data-section-id="${sectionId}"]`)
        .data('mediaObjectId');

      // Update helper object noting we want the new media clip to auto start
      this.switchPlayerHelper = {
        active: true,
        data: {},
        paused: false
      };

      // Go to next section
      this.getNewStreamAjax(
        sectionId,
        `/media_objects/${mediaObjectId}/section/${sectionId}`
      );
    }
  }

  /**
   * Event handler for clicking on a section link
   * @function handleSectionClick
   * @param  {Object} e - Event object
   * @return {void}
   */
  handleSectionClick(e) {
    const target = e.target;
    const dataset = e.target.dataset;
    e.preventDefault();

    // Stop execution if a non-section link was clicked
    if (!dataset.segment) {
      return;
    }

    // Clicked on a different section
    if (dataset.segment !== this.currentStreamInfo.id) {
      let id = target.dataset.segment;
      let url = target.dataset.nativeUrl.split('?')[0];

      // Capture clicked segment or section element id
      this.switchPlayerHelper = {
        active: true,
        data: dataset,
        paused: this.mediaElement.paused
      };
      this.getNewStreamAjax(id, url);
    } else {
      // Clicked within the same section...
      const parentPanel = $(target).closest('div[class*=panel]');
      const isHeader =
        parentPanel.hasClass('panel-heading') ||
        parentPanel.hasClass('panel-title');
      const time = isHeader
        ? 0
        : parseFloat(this.segmentsMap[target.id].fragmentbegin);
      this.mediaElement.setCurrentTime(time);
    }

    this.mejsUtility.showControlsBriefly(this.player);
  }

  /**
   * Show/display a highlighted segment region in MEJS's UI time rail
   * @function handleSectionHighlighting
   * @param {string} activeId - current active segment id - the id of section playing
   * @param {number} currentTime - current player time value in seconds
   * @return {void}
   */
  handleSectionHighlighting(activeId, currentTime) {
    // There is no segments map, which means we don't want to hightlight any segment
    if (!this.hasSections()) {
      return;
    }

    const t = this.mejsTimeRailHelper.calculateSegmentT(
      this.segmentsMap[activeId],
      this.currentStreamInfo
    );

    // A new section is now active
    if (activeId && activeId !== this.activeSegmentId) {
      this.activeSegmentId = activeId;
      // Need to update time rail highlighting
      this.highlightTimeRail(t, this.activeSegmentId);
      this.mejsUtility.highlightSectionLink(this.activeSegmentId);
    } else if (!activeId) {
      // No current segment, so remove highlighting
      this.activeSegmentId = '';
      // Need to update time rail highlighting
      this.highlightTimeRail(t);
      this.mejsUtility.highlightSectionLink();
    }
  }
  /**
   * MediaElement render error callback function
   * @function handleError
   * @param  {Object} error - The error object
   * @param  {Object} mediaElement - The wrapper that mimics all the native events/properties/methods for all renderers
   * @param  {Object} originalNode - The original HTML video, audio or iframe tag where the media was loaded originally
   * @return {void}
   */
  handleError(error, mediaElement, originalNode) {
    console.log('MEJS CREATE ERROR: ' + error);
  }
  /**
   * MediaElement render success callback function
   * @function handleSuccess
   * @param  {Object} mediaElement - The wrapper that mimics all the native events/properties/methods for all renderers
   * @param  {Object} originalNode - The original HTML video, audio or iframe tag where the media was loaded originally
   * @param  {Object} instance - The instance object
   * @return {void}
   */
  handleSuccess(mediaElement, originalNode, instance) {
    this.mediaElement = mediaElement;

    // Grab instance of player
    if (!this.player) {
      this.player = instance;
    }

    if (this.player && this.player.media && this.player.media.hlsPlayer && this.player.media.hlsPlayer.config) {
      // Workaround for hlsError bufferFullError: Set max buffer length to 2 minutes
      this.player.media.hlsPlayer.config.maxMaxBufferLength = 120;
    }

    // Toggle captions on if toggleable and previously on
    if (this.mediaType==="video" && this.player.options.toggleCaptionsButtonWhenOnlyOne) {
      if (this.localStorage.getItem('captions') !== '' && this.player.tracks && this.player.tracks.length===1) {
        this.player.setTrack(this.player.tracks[0].trackId, (typeof keyboard !== 'undefined'));
      }
    }

    // Make the player visible
    this.revealPlayer(instance);

    this.emitSuccessEvent();

    // Handle 'canplay' events fired by player
    this.mediaElement.addEventListener(
      'canplay',
      this.handleCanPlay.bind(this)
    );

    // Handle 'volumechange' events fired by player
    this.mediaElement.addEventListener(
      'volumechange',
      this.handleVolumeChange.bind(this)
    );

    // Handle 'captionschange' events fired by player
    this.mediaElement.addEventListener(
      'captionschange',
      this.handleCaptionsChange.bind(this)
    );

    // Handle 'ended' event fired by player
    this.mediaElement.addEventListener('ended', this.handleEnded.bind(this));

    // Show highlighted time in time rail
    if (this.highlightRail) {
      const t = this.mejsTimeRailHelper.calculateSegmentT(
        this.segmentsMap[this.activeSegmentId],
        this.currentStreamInfo
      );

      // Create our custom time rail highlighter element
      this.highlightSpanEl = this.mejsTimeRailHelper.createTimeHighlightEl(
        document.getElementById('content')
      );
      this.highlightTimeRail(t, this.activeSegmentId);
    }

    // Filter playlist item player from handling MEJS's time update event
    if (Object.keys(this.playlistItem).length === 0) {
      // Listen for timeupdate events in player, to show / hide highlighted sections, etc.
      this.mediaElement.addEventListener(
        'timeupdate',
        this.handleTimeUpdate.bind(this)
      );
    }
  }

  /**
   * Callback function to handle MEJS's 'timeupdate' event, which happens continuously
   * @function handleTimeUpdate
   * @return {void}
   */
  handleTimeUpdate() {
    if (!this.player) {
      return;
    }
    const currentTime = this.player.getCurrentTime();
    const activeId = this.mejsUtility.getActiveSegmentId(
      this.segmentsMap,
      currentTime
    );

    // Handle section highlighting
    this.handleSectionHighlighting(activeId, currentTime);
  }

  /**
   * Helper function which deterimines whether the current UI has navigatable "Sections"
   * @function hasSections
   * @return {Boolean} Boolean value whether the UI has navigatable "Sections" content
   */
  hasSections() {
    return Object.keys(this.segmentsMap).length > 0;
  }

  /**
   * Update section links to reflect active section playing
   * @function highlightSectionLink
   * @param  {string} segmentId - HTML node of section link clicked on <a>
   * @return {void}
   */
  highlightSectionLink(segmentId) {
    const accordionEl = document.getElementById('accordion');
    const htmlCollection = accordionEl.getElementsByClassName('playable wrap');
    let segmentLinks = [].slice.call(htmlCollection);
    let segmentEl = document.getElementById(segmentId);

    // Clear "active" style on all section links
    segmentLinks.forEach(segmentLink => {
      segmentLink.classList.remove('current-stream');
      segmentLink.classList.remove('current-section');
    });
    if (segmentEl) {
      // Add style to clicked segment link
      segmentEl.classList.add('current-stream');
      // Add style to section title
      document
        .getElementById('section-title-' + segmentEl.dataset.segment)
        .classList.add('current-section');
    }
  }

  /**
   * Highlight a range of the Mediaelement player's time rail
   * @function highlightTimeRail
   * @param {Array} t Start end time array
   * @param {string} activeSegmentId
   * @return {void}
   */
  highlightTimeRail(t, activeSegmentId) {
    this.highlightSpanEl.setAttribute(
      'style',
      this.mejsTimeRailHelper.createTimeRailStyles(t, this.currentStreamInfo)
    );

    // This is a way to piggyback updating the track scrubber based on Sections highlighting
    // calculations.
    if (this.player.trackScrubberObj) {
      let updatedStartEndTimes = this.mejsTimeRailHelper.getUpdatedRangeTimes(
        t,
        activeSegmentId,
        this.currentStreamInfo
      );

      this.player.trackScrubberObj.initializeTrackScrubber(
        ...updatedStartEndTimes,
        this.currentStreamInfo
      );
    }
  }

  /**
   * Configure and create the MediaElement instance
   * @function initializePlayer
   * @return {void}
   */
  initializePlayer() {
    let currentStreamInfo = this.currentStreamInfo;
    // Mediaelement default root level configuration
    let defaults = {
      pluginPath: '/assets/mediaelement/shims/',
      features: this.features,
      poster: currentStreamInfo.poster_image || null,
      success: this.handleSuccess.bind(this),
      error: this.handleError.bind(this),
      embed_title: currentStreamInfo.embed_title,
      link_back_url: currentStreamInfo.link_back_url,
      qualityText: 'Stream Quality',
      defaultQuality: this.defaultQuality,
      toggleCaptionsButtonWhenOnlyOne: true,
      startVolume: this.localStorage.getItem('startVolume') || 1.0,
      startLanguage: this.localStorage.getItem('captions') || ''
    };

    // Add duration as a root level config for Android devices
    if(mejs.Features.isAndroid) {
      defaults.duration = currentStreamInfo.duration
    }

    if (this.currentStreamInfo.cookie_auth) {
      defaults.hls = {
        xhrSetup: (xhr, url) => {
          xhr.withCredentials = true;
        }
      };
    }

    let promises = [];
    const playlistIds = this.playlistItem
      ? [this.playlistItem.playlist_id, this.playlistItem.id]
      : [];

    // Remove quality feature for IE and Android
    if (
      mejs.Features.isAndroid ||
      !!navigator.userAgent.match(/MSIE /) ||
      !!navigator.userAgent.match(/Trident.*rv\:11\./)
    ) {
      defaults.features = defaults.features.filter(e => e !== 'quality');
    }

    // Remove video player controls/plugins if it's not a video stream
    if (!currentStreamInfo.is_video) {
      defaults.features = defaults.features.filter(
        e => e !== 'createThumbnail'
      );
      delete defaults.poster;
    }

    // Get any asynchronous configuration data needed to build the player instance
    // Markers
    promises.push(this.mejsMarkersHelper.getMarkers(...playlistIds));
    Promise.all(promises)
      .then(values => {
        const markers = values[0];
        const markerConfig =
          markers.length > 0
            ? this.mejsMarkersHelper.buildMarkersConfig(markers)
            : {};

        // Combine all configurations
        let fullConfiguration = Object.assign({}, defaults, markerConfig);
        // Create a MediaElement instance
        this.player = new MediaElementPlayer(
          `mejs-avalon-${this.mediaType}`,
          fullConfiguration
        );
        // Add default title from stream info which mejs plugins can access
        this.player.options.playlistItemDefaultTitle = this.currentStreamInfo.embed_title;

        // initialize global variable currentPlayer
        currentPlayer = this.player;

        // Add a reference to this wrapper class for ease of access from inside Avalon-created plugins
        this.player.avalonWrapper = this;
      })
      .catch(error => {
        console.log('Promise rejection error');
      });
  }

  /**
   * Play a range of a media file from the start time
   * @function playRange
   * @return {void}
   */
  playRange() {
    const begin = parseFloat(this.switchPlayerHelper.data.fragmentbegin) || 0;
    // Reset the flag to default 'off'
    this.switchPlayerHelper.active = false;
    this.mediaElement.setCurrentTime(begin);
    // If the player was previously playing, continue playing.
    if (!this.switchPlayerHelper.paused) {
      this.mediaElement.play();
    }
  }

  /**
   * Remove MediaElement player instance
   * @function removePlayer
   * @return {void}
   */
  removePlayer() {
    let tagEls = null;

    if (!this.player) {
      return;
    }

    // Pause the player
    if (!this.player.paused) {
      this.player.pause();
    }
    this.player.remove();
    delete this.player;
    // Grab either the <audio> or <video> element
    tagEls = document.getElementsByTagName(this.mediaType);
    if (tagEls.length > 0) {
      const tagEl = tagEls[0];
      tagEl.parentNode.removeChild(tagEl);
    }
  }

  /**
   * Display the media element, which was originally hidden so the html element
   * <audio> or <video> didn't show up before MediaElement wrapped player's display.
   * @function revealPlayer
   * @param  {Object} instance - MediaElement instance
   * @return {void}
   */
  revealPlayer(instance) {
    let container = instance.container;
    let sourceEls = [];

    container.classList.remove('invisible');
    sourceEls = container.getElementsByClassName('mejs-avalon');
    for (let i = 0, count = sourceEls.length; i < count; i++) {
      sourceEls[i].classList.remove('invisible');
    }
  }

  /**
   * Update class vars with new stream data
   * @function setContextVars
   * @param  {Object} currentStreamInfo - New stream information returned from AJAX request
   * @param {Array} playlistItemT - Array of start / end times for a playlist item
   * @return {void}
   */
  setContextVars(currentStreamInfo, playlistItemT) {
    this.currentStreamInfo = currentStreamInfo;

    if (playlistItemT) {
      this.currentStreamInfo.t = playlistItemT;
    }
    this.mediaType = currentStreamInfo.is_video === true ? 'video' : 'audio';
    this.segmentsMap = this.mejsUtility.createSegmentsMap(
      document.getElementById('accordion'),
      currentStreamInfo
    );
  }

  /**
   * Update section and lti section share links and embed code when switching sections
   * @function updateShareLinks
   * @return {void}
   */
  updateShareLinks() {
    const sectionShareLink = this.currentStreamInfo.link_back_url;
    const ltiShareLink = this.currentStreamInfo.lti_share_link;
    const embedCode = this.currentStreamInfo.embed_code;
    $('#share-link-section')
      .val(sectionShareLink)
      .attr('placeholder', sectionShareLink);
    $('#ltilink-section')
      .val(ltiShareLink)
      .attr('placeholder', ltiShareLink);
    $('#embed-part').val(embedCode);
  }
}
