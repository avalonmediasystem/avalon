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

    // Unpack player configuration object for the new player.
    // This allows for variable params to be sent in.
    this.currentStreamInfo = configObj.currentStreamInfo || {};
    this.features = configObj.features || {};
    this.highlightRail = configObj.highlightRail;
    this.playlistItem = configObj.playlistItem || {};

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
    const accordionEl = document.getElementById('accordion');

    if (accordionEl) {
      accordionEl.addEventListener('click', this.handleSectionClick.bind(this));
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
    // TODO: This is an example of something we could hook into.  Don't need quite yet but might...
    const myEvent = new CustomEvent('mejs4handleSuccess', {
      detail: {
        foo: 'bar'
      }
    });
    document.getElementById('content').dispatchEvent(myEvent);
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
    if (this.switchPlayerHelper.active) {
      this.playRange();
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
    if (Object.keys(this.segmentsMap).length === 0) {
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
   * MediaElement render success callback function
   * @function handleSuccess
   * @param  {Object} mediaElement - The wrapper that mimics all the native events/properties/methods for all renderers
   * @param  {Object} originalNode - The original HTML video, audio or iframe tag where the media was loaded originally
   * @param  {Object} instance - The instance object
   * @return {void}
   */
  handleSuccess(mediaElement, originalNode, instance) {
    this.mediaElement = mediaElement;

    // Make the player visible
    this.revealPlayer(instance);

    // Grab instance of player
    if (!this.player) {
      this.player = this.mediaElement;
    }

    this.emitSuccessEvent();

    // Handle 'canplay' events fired by player
    this.mediaElement.addEventListener(
      'canplay',
      this.handleCanPlay.bind(this)
    );

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

    // If track scrubber feature is active, grab new start / end values
    // and initialize a new scrubber
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
      embed_title: currentStreamInfo.embed_title,
      link_back_url: currentStreamInfo.link_back_url,
      qualityText: 'Stream Quality',
      toggleCaptionsButtonWhenOnlyOne: true
    };
    let promises = [];
    const playlistIds = this.playlistItem
      ? [this.playlistItem.playlist_id, this.playlistItem.id]
      : [];

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
}
