/**
 * @class MEJSPlayer
 * @classdesc Wrapper for MediaElementPlayer interactions
 */
class MEJSPlayer {
  constructor(currentStreamInfo) {
    this.player = undefined
    this.currentStreamInfo = currentStreamInfo
    this.addSectionsClickListener()
    // audio or video file?
    this.mediaType = (this.currentStreamInfo.is_video === true) ? 'video' : 'audio'
    this.initializePlayer()
  }

  /**
   * Add a listener for clicks on the 'Sections' links
   * @function addSectionsClickListener
   * @return {void}
   */
  addSectionsClickListener() {
    const accordionEl = document.getElementById('accordion')

    // Clickable sections are present in DOM
    if (accordionEl) {
      accordionEl.addEventListener('click', (e) => {
        let target = e.target

        e.preventDefault()
        if (target.dataset.segment === this.currentStreamInfo.id) {
          // Clicked on current stream section link, play from beginning
          this.player.setCurrentTime(0)
        } else {
          // If they clicked on a new item, get new item stream info
          this.getNewStreamAjax(target)
          this.updateSectionLinks(target)
        }
      })
    }
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
      node.setAttribute('preload', 'auto')
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
        markup += `<source src="${source.url}" data-quality="${source.quality}" data-plugin-type="native" type="application/vnd.apple.mpegURL" />`
      })
      currentStreamInfo.stream_flash.map((source) => {
        markup += `<source src="${source.url}" data-quality="${source.quality}" data-plugin-type="flash" type="audio/rtmp" />`
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
  createNewPlayer() {
    let itemScope = document.querySelector('[itemscope="itemscope"]')
    let node = this.createMarkup()

    // Mount new <audio> or <video> element to the DOM and initialize
    // a new MediaElement instance.
    itemScope.appendChild(node)
    this.initializePlayer()
  }

  /**
   * Configuration of the Markers plugin
   * @function getMarkers
   * @return {obj} obj - Markers plugin specific configuration
   */
  getMarkers () {
    let obj = {
      markerColor: '#86ad96', // Optional : Specify the color of the marker
      markers:['4','16','20','25','35','40'], // Specify marker times in seconds
      markerCallback: function(media,time){
          // Do something here
      }
    }
    return obj
  }

  /**
   * Make AJAX request for clicked item's stream data
   * @function getNewStreamAjax
   * @param  {Object} target - node <a> element clicked
   * @return {void}
   */
  getNewStreamAjax (target) {
    let segment = target.dataset.segment
    let nativeUrl = target.dataset.nativeUrl

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
   * MediaElement render success callback function
   * @function handleSuccess
   * @param  {Object} mediaElement - The wrapper that mimics all the native events/properties/methods for all renderers
   * @param  {Object} originalNode - The original HTML video, audio or iframe tag where the media was loaded originally
   * @param  {Object} instance - The instance object
   * @return {void}
   */
  handleSuccess (mediaElement, originalNode, instance) {
    this.revealPlayer(instance)
  }

  /**
   * Configure and create the MediaElement instance
   * @function initializePlayer
   * @return {void}
   */
  initializePlayer () {
    // Mediaelement default root level configuration
    let defaults = {
      pluginPath: "/",
      features: ['playpause','loop','progress','current','duration','volume','quality','markers'],
      success: this.handleSuccess.bind(this)
    }
    let markers = this.getMarkers()
    // Combine all configurations
    let fullConfiguration = { ...defaults, ...markers }

    // Create a MediaElement instance
    this.player = new MediaElementPlayer(`mejs-avalon-${this.mediaType}`, fullConfiguration);
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
  }

  /**
   * Update section links to reflect active section playing
   * @function updateSectionLinks
   * @param  {Object} target - HTML node of section link clicked on <a>
   * @return {void}
   */
  updateSectionLinks(target) {
    const accordionEl = document.getElementById('accordion')
    const htmlCollection = accordionEl.getElementsByClassName('playable wrap')
    const sectionLinks = Array.from(htmlCollection)

    // Clear selected styles on all section links
    sectionLinks.map((sectionLink) => {
      sectionLink.classList.remove('current-stream')
      sectionLink.classList.remove('current-section')
    })
    // Add selected style to clicked section link
    target.classList.add('current-stream')
    target.classList.add('current-section')
  }
}
