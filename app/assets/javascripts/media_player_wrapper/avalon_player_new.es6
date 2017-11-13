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
    // Unpack player configuration object for the new player.
    // This allows for variable params to be sent in.
    this.currentStreamInfo = configObj.currentStreamInfo || {},
    this.features = configObj.features || {},
    this.highlightRail = configObj.highlightRail,
    this.playlistItem = configObj.playlistItem || {},

    // Wrapper for MediaElement instance which interfaces with properties, events, etc.
    this.mediaElement = null
    // Actual MediaElement instance
    this.player = null
    // Add click listeners on sections
    this.addSectionsClickListener()
    // audio or video file?
    this.mediaType = (this.currentStreamInfo.is_video === true) ? 'video' : 'audio'

    // Helper object when loading a new MEJS player instance (ie. a different media object source section link clicked)
    this.switchPlayerHelper = {
      active: false,
      data: {},
      paused: false
    }

    // Array of all current segments for media object
    this.segmentsMap = this.createSegmentsMap()
    // Holder for currently active segment DOM element 'id' attribute
    this.activeSegmentId = ''

    // Initialize the player
    this.initializePlayer()
  }

  /**
   * Add a listener for clicks on the 'Sections' links
   * @function addSectionsClickListener
   * @return {void}
   */
  addSectionsClickListener() {
    const accordionEl = document.getElementById('accordion')

    if (accordionEl) {
      accordionEl.addEventListener('click', this.handleSectionClick.bind(this))
    }
  }

  /**
   * Create a map object which represents clickable time range segments within the media object
   * @function createSegmentsMap
   * @return {Object} segmentsMap Mapping of all current segments, key'd on the
   * <a> element's 'id' attribute
   */
  createSegmentsMap () {
    const el = document.getElementById('accordion')
    const segmentEls = (el) ? [].slice.call(el.querySelectorAll('[data-segment="' + this.currentStreamInfo.id + '"]')) : []
    let segmentsMap = {}

    segmentEls.forEach((el) => {
      if (el.id) {
        segmentsMap[el.id] = Object.assign({}, el.dataset)
      }
    })
    return segmentsMap
  }

  /**
   * Create HTML markup for <audio> or <video> element
   * @function createMarkup
   * @return {string} markup - HTML markup containing <audio> or <video> and <source>s
   */
  createMarkup() {
    let currentStreamInfo = this.currentStreamInfo
    let markup = ''
    let node = null

    // Create <video> markup
    if (this.mediaType === 'video') {
      node = document.createElement('video')
      node.setAttribute('id', 'mejs-avalon-video')
      node.setAttribute('controls', '')
      node.setAttribute('width', '450')
      node.setAttribute('height', '309')
      node.setAttribute('style', 'width: 100%; height: 100%')
      if (currentStreamInfo.poster_image) {
        node.setAttribute('poster', currentStreamInfo.poster_image)
      }
      node.setAttribute('preload', 'true')
      node.classList.add('mejs-avalon')
      node.classList.add('invisible')

      // Add <source>s
      currentStreamInfo.stream_hls.map((source) => {
        markup += `<source src="${source.url}" type="application/x-mpegURL" data-quality="${source.quality}"/>`
      })

      // Add captions
      if (currentStreamInfo.captions_path) {
        markup += `<track srclang="en" kind="subtitles" type="${currentStreamInfo.captions_format}" src="${currentStreamInfo.captions_path}"></track>`
      }
    }
    // Create <audio> markup
    if (this.mediaType === 'audio') {
      node = document.createElement('audio')
      node.setAttribute('id', 'mejs-avalon-audio')
      node.setAttribute('controls', '')
      node.setAttribute('style', 'width: 100%;')
      node.setAttribute('preload', 'true')
      node.classList.add('mejs-avalon')
      node.classList.add('invisible')

      // Add <source>s
      currentStreamInfo.stream_hls.map((source) => {
        markup += `<source src="${source.url}" data-quality="${source.quality}" data-plugin-type="native" type="application/x-mpegURL" />`
      })
      markup += `</audio>`
    }
    node.innerHTML = markup
    return node
  }

  /**
   * Create the pieces for a new MediaElement player
   * @function createNewPlayer
   * @return {void}
   */
  createNewPlayer () {
    let itemScope = document.querySelector('[itemscope="itemscope"]')
    let node = this.createMarkup()

    // Mount new <audio> or <video> element to the DOM and initialize
    // a new MediaElement instance.
    itemScope.appendChild(node)
    this.initializePlayer()
  }

  /**
   * Create an element representing highlighted segment area in MEJS's time rail
   * and add it to the DOM
   * @function createTimeHighlightEl
   * @return {void}
   */
  createTimeHighlightEl () {
    let highlightSpanEl = document.getElementById('content').querySelector('.mejs-highlight-clip')

    // Create the highlight DOM element if doesn't exist
    if (!highlightSpanEl) {
      highlightSpanEl = document.createElement('span')
      highlightSpanEl.classList.add('mejs-highlight-clip')
      $('.mejs__time-total')[0].appendChild(highlightSpanEl)
      this.highlightSpanEl = highlightSpanEl
    }
  }

  /**
   * Create a CSS 'style' string to plug into an inline style attribute
   * @function createTimeRailStyles
   * @return {string} Ex. left: 10%; width: 50%;
   */
  createTimeRailStyles (activeSegmentId) {
    const duration = this.currentStreamInfo.duration
    const segment = this.segmentsMap[activeSegmentId]
    let t = []

    // No active segment, remove highlight style
    if (!activeSegmentId) {
      return 'left: 0%; width: 0%;'
    }

    // Use the active segment fragment,
    try {
      t = [parseFloat(segment.fragmentbegin), parseFloat(segment.fragmentend)]
    } catch(e) {
      t = this.currentStreamInfo.t.slice(0)
    }

    // Ensure t range array has valid values
    t[0] = (isNaN(parseFloat(t[0]))) ? 0 : t[0]
    t[1] = (t.length < 2 || isNaN(parseFloat(t[1]))) ? duration : t[1]

    // Calculate start and end percentage values for the highlight style attribute
    let startPercent = Math.round((t[0] / duration) * 100)
    startPercent = Math.max(0, Math.min(100, startPercent))
    let endPercent = Math.round((t[1] / duration) * 100)
    endPercent = Math.max(0, Math.min(100, endPercent))

    // Make the length of time highlight 0 if it would span the entire time length
    if (startPercent === 0 && endPercent === 100) {
      endPercent = 0
    }
    return 'left: ' + startPercent + '%; width: ' + (endPercent - startPercent) + '%;'
  }

  /**
   * Get the segment for player's current time value (if one exists)
   * @function getActiveSegmentId
   * @return {string} the active segment id
   */
  getActiveSegmentId (segmentsMap, currentTime) {
    let activeId = ''

    for (let segmentId in segmentsMap) {
      if (segmentsMap.hasOwnProperty(segmentId)) {
        let begin = parseFloat(segmentsMap[segmentId].fragmentbegin)
        let end = parseFloat(segmentsMap[segmentId].fragmentend)

        if ( (segmentsMap.hasOwnProperty(segmentId)) && (currentTime >= begin && currentTime < end) ) {
          activeId = segmentId
        }
      }
    }
    return activeId
  }

  /**
   * Get any playlist item markers if a playlist item is specified
   * @function getMarkers
   * @return {obj} obj - Markers plugin specific configuration
   */
  getMarkers (resolve, reject) {
    let returnObj = {}
    let markersConfig = {
      markerColor: '#86ad96', // Optional : Specify the color of the marker
    }

    // Check if a playlist item is specified, because playlist items use markers
    // and we'll need to grab markers from the playlist item
    if (Object.keys(this.playlistItem).length > 0) {
      const playlistItem = this.playlistItem
      let markers = []

      $.ajax({
        url: '/playlists/' + playlistItem.playlist_id + '/items/' + playlistItem.id + '.json',
        dataType: 'json'
      }).done((response) => {
        if (response.message) {
          //TODO: display error message somehow (500 or 401)
        }
        else if (response.markers && response.markers.length > 0) {
          markers = response.markers.map((marker) => {
            return marker.start_time
          })
        }
        // Array of marker time values in seconds
        markersConfig.markers = markers
        resolve(markersConfig)
      }).fail((error) => {
        reject({})
      });
    } else {
      // No playlist item, therefore no markers needed
      resolve({})
    }
  }

  /**
   * Make AJAX request for clicked item's stream data
   * @function getNewStreamAjax
   * @param  {Object} target - node <a> element clicked
   * @return {void}
   */
  getNewStreamAjax (target) {
    const segment = target.dataset.segment
    const nativeUrl = target.dataset.nativeUrl.split('?')[0]

    $.ajax({
      url: nativeUrl + '/stream',
      dataType: 'json',
      data: {
        content: segment
      }
    }).done((response) => {
      this.removePlayer()
      this.setContextVars(response)
      this.createNewPlayer()
    }).fail((error) => {
      console.log('error', error)
    })
  }

  /**
   * Stub function to demonstrate future usage of MEJS4 playlist plugin
   * @function getPlaylists
   * @return {void}
   */
  getPlaylists () {
    const obj = {
      playlist: [{
        src: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/mp4/BigBuckBunny.mp4',
        title: 'Big Buck Bunny Test'
      }, {
        src: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/mp4/BigBuckBunny.mp4',
        title: 'Big Buck Bunny Test 2'
      }]
    }
    return {}
  }

  /**
   * Event handler for MediaElement's 'canplay' event
   * At this point can play, pause, set time on player instance
   * @function handleCanPlay
   * @return {void}
   */
  handleCanPlay () {
    this.mediaElement.removeEventListener('canplay')

    // Do we play a specified range of the media file?
    if (this.switchPlayerHelper.active) {
      this.playRange()
    }
  }

  /**
   * Handle updating progress of the track scrubber, if the feature/plugin is enabled
   * @function handleScrubberProgress
   * @param activeId - current active segment id - the id of section playing
   * @param currentTime - current player time value in seconds
   * @return {void}
   */
  handleScrubberProgress (activeId, currentTime) {
    const player = this.player
    if (!player.trackScrubberObj) {
      return
    }
    player.trackScrubberObj.updateTrackScrubberProgressBar(currentTime)
  }

  /**
   * Event handler for clicking on a section link
   * @function handleSectionClick
   * @param  {Object} e - Event object
   * @return {void}
   */
  handleSectionClick (e) {
    const target = e.target
    const dataset = e.target.dataset
    e.preventDefault()

    // Stop execution if a non-section link was clicked
    if (!dataset.segment) { return }

    // Clicked on a different section
    if (dataset.segment !== this.currentStreamInfo.id) {
      // Capture clicked segment or section element id
      this.switchPlayerHelper = {
        active: true,
        data: dataset,
        paused: this.mediaElement.paused
      }
      this.getNewStreamAjax(target)
    } else {
      // Clicked within the same section...
      const parentPanel = $(target).closest('div[class*=panel]')
      const isHeader = parentPanel.hasClass('panel-heading') || parentPanel.hasClass('panel-title')
      const time = (isHeader) ? 0 : parseFloat(this.segmentsMap[target.id].fragmentbegin)
      this.mediaElement.setCurrentTime(time)
    }
  }

  /**
   * Show/display a highlighted segment region in MEJS's UI time rail
   * @function handleSectionHighlighting
   * @param {string} activeId - current active segment id - the id of section playing
   * @param {number} currentTime - current player time value in seconds
   * @return {void}
   */
  handleSectionHighlighting (activeId, currentTime) {
    // There is no segments map, which means we don't want to hightlight any segment
    if (Object.keys(this.segmentsMap).length === 0) {
      return;
    }

    // Current active segment exists, and is different from before
    if (activeId && activeId !== this.activeSegmentId) {
      this.activeSegmentId = activeId
      this.highlightTimeRail(this.activeSegmentId)
      this.highlightSectionLink(this.activeSegmentId)
    }
    // No current segment, so remove highlighting
    else if (!activeId) {
      this.activeSegmentId = ''
      this.highlightTimeRail()
      this.highlightSectionLink()
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
  handleSuccess (mediaElement, originalNode, instance) {
    this.mediaElement = mediaElement

    // Show the player in success callback
    this.revealPlayer(instance)

    // Grab instance of player
    if (!this.player) {
      this.player = this.mediaElement
    }

    // Handle 'canplay' events fired by player
    this.mediaElement.addEventListener('canplay', this.handleCanPlay.bind(this))

    // Show highlighted time in time rail
    if (this.highlightRail) {
      // Create our custom time rail highlighter element
      this.createTimeHighlightEl()
      this.highlightTimeRail(this.activeSegmentId)
    }

    // Listen for timeupdate events in player, to show / hide highlighted sections, etc.
    this.mediaElement.addEventListener('timeupdate', this.handleTimeUpdate.bind(this))
  }

  /**
   * Callback function to handle MEJS's 'timeupdate' event, which happens continuously
   * @function handleTimeUpdate
   * @return {void}
   */
  handleTimeUpdate () {
    const currentTime = this.player.getCurrentTime()
    const activeId = this.getActiveSegmentId(this.segmentsMap, currentTime)

    // Handle section highlighting
    this.handleSectionHighlighting(activeId, currentTime)
    // Handle updating the track scrubber, if enabled
    this.handleScrubberProgress(activeId, currentTime)
  }

  /**
   * Update section links to reflect active section playing
   * @function highlightSectionLink
   * @param  {string} segmentId - HTML node of section link clicked on <a>
   * @return {void}
   */
  highlightSectionLink (segmentId) {
    const accordionEl = document.getElementById('accordion')
    const htmlCollection = accordionEl.getElementsByClassName('playable wrap')
    let segmentLinks = [].slice.call(htmlCollection)
    let segmentEl = document.getElementById(segmentId)

    // Clear "active" style on all section links
    segmentLinks.forEach((segmentLink) => {
      segmentLink.classList.remove('current-stream')
      segmentLink.classList.remove('current-section')
    })
    if (segmentEl) {
      // Add style to clicked segment link
      segmentEl.classList.add('current-stream')
      // Add style to section title
      document.getElementById('section-title-' + segmentEl.dataset.segment).classList.add('current-section')
    }
  }

  /**
   * Highlight a section of the Mediaelement player's time rail
   * @function highlightTimeRail
   * @param {string} activeSegmentId
   * @return {void}
   */
  highlightTimeRail (activeSegmentId) {
    this.highlightSpanEl.setAttribute('style', this.createTimeRailStyles(activeSegmentId))

    // If track scrubber feature is active, initialize a new scrubber
    if (this.player.trackScrubberObj) {
      this.reInitializeScrubber(activeSegmentId)
    }
  }

  /**
   * Configure and create the MediaElement instance
   * @function initializePlayer
   * @return {void}
   */
  initializePlayer () {
    let currentStreamInfo = this.currentStreamInfo;
    // Mediaelement default root level configuration
    let defaults = {
      alwaysShowControls: true,
      pluginPath: "/assets/mediaelement/shims/",
      features: this.features,
      poster: currentStreamInfo.poster_image || null,
      success: this.handleSuccess.bind(this)
    }
    let promises = []

    // Remove video player controls/plugins if it's not a video stream
    if (!currentStreamInfo.is_video) {
      defaults.features = defaults.features.filter(e => e !== 'createThumbnail')
      delete defaults.poster;
    }

    // Get any asynchronous configuration data needed to
    // create a new player instance
    promises.push(new Promise(this.getMarkers.bind(this)))
    Promise.all(promises).then((values) => {
      const markerConfig = values[0]

      // Combine all configurations
      let fullConfiguration = Object.assign({}, defaults, markerConfig)
      // Create a MediaElement instance
      this.player = new MediaElementPlayer(`mejs-avalon-${this.mediaType}`, fullConfiguration)
      // Add default title from stream info which mejs plugins can access
      this.player.options.playlistItemDefaultTitle = this.currentStreamInfo.embed_title
    }).catch((error) => {
      console.log('Promise rejection error')
    });
  }

  /**
   * Play a range of a media file from the start time
   * @function playRange
   * @return {void}
   */
  playRange () {
    const begin = parseFloat(this.switchPlayerHelper.data.fragmentbegin) || 0
    // Reset the flag to default 'off'
    this.switchPlayerHelper.active = false
    this.mediaElement.setCurrentTime(begin)
    // If the player was previously playing, continue playing.
    if (!this.switchPlayerHelper.paused) {
      this.mediaElement.play()
    }
  }

  /**
   * Re-initialize the track scrubber in player
   * @function reInitializeScrubber
   * @param {string} activeSegmentId - Active segment id
   * @return {void}
   */
  reInitializeScrubber (activeSegmentId) {
    const stream = this.currentStreamInfo
    let start = stream.t[0] || 0
    let end = stream.t[1] || stream.duration

    // Feed the scrubber active section data, instead of default data
    if (activeSegmentId && this.segmentsMap && this.segmentsMap.hasOwnProperty(activeSegmentId)) {
      start = this.segmentsMap[activeSegmentId].fragmentbegin
      end = this.segmentsMap[activeSegmentId].fragmentend
    }
    this.player.trackScrubberObj.initializeTrackScrubber(start, end, stream)
  }

  /**
   * Remove MediaElement player instance
   * @function removePlayer
   * @return {void}
   */
  removePlayer () {
    let tagEls = null

    if (!this.player.paused) {
    	this.player.pause()
    }
    this.player.remove()
    delete this.player
    // Grab either the <audio> or <video> element
    tagEls = document.getElementsByTagName(this.mediaType)
    if (tagEls.length > 0) {
      const tagEl = tagEls[0]
      tagEl.parentNode.removeChild(tagEl)
    }
  }

  /**
   * Display the media element, which was originally hidden so the html element
   * <audio> or <video> didn't show up before MediaElement wrapped player's display.
   * @function revealPlayer
   * @param  {Object} instance - MediaElement instance
   * @return {void}
   */
  revealPlayer (instance) {
    let container = instance.container
    let sourceEls = []

    container.classList.remove('invisible')
    sourceEls = container.getElementsByClassName('mejs-avalon')
    for (let i = 0, count = sourceEls.length; i < count; i++) {
      sourceEls[i].classList.remove('invisible')
    }
  }

  /**
   * Update class vars with new stream data
   * @function setContextVars
   * @param  {Object} currentStreamInfo - New stream information returned from AJAX request
   * @return {void}
   */
  setContextVars (currentStreamInfo) {
    this.currentStreamInfo = currentStreamInfo
    this.mediaType = (currentStreamInfo.is_video === true) ? 'video' : 'audio'
    this.segmentsMap = this.createSegmentsMap()
  }

}
