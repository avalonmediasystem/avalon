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
    buildplaylistItems (player, controls, layers, media) {
        // This allows us to access options and other useful elements already set.
        // Adding variables to the object is a good idea if you plan to reuse
        // those variables in further operations.
        const t = this;
        let playlistItemsObj = t.playlistItemsObj;

        playlistItemsObj.mejsUtility = new MEJSUtility();
        playlistItemsObj.player = player;
        playlistItemsObj.currentStreamInfo = mejs4AvalonPlayer.currentStreamInfo;
        // Click listeners for the DOM
        playlistItemsObj.addClickListeners();
        // Handle continuous MEJS time update event
        media.addEventListener('timeupdate', playlistItemsObj.handleTimeUpdate.bind(this));
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
    cleanplaylistItems (player, controls, layers, media) {
      // Remove click listener on playlist items
      $('#right-column').find('.side-playlist').off('click');
    },

    // Other optional public methods (all documented according to JSDoc specifications)

    /**
     * The 'playlistItemsObj' object acts as a namespacer for this plugin's
     * specific variables and methods, so as not to pollute global or MEJS scope.
     * @type {Object}
     */
    playlistItemsObj: {
      addClickListeners() {
        if (this.$sidePlaylist) {
          // Handle click on entire Playlists right column area
          this.$sidePlaylist.on('click', (e) => {
            // Only handle clicks on <a> elements
            if (e.target.nodeName === 'A') {
              this.handleClick(e)
            }
          });
        }
      },

      currentStreamInfo: null,

      getPlayer() {
        let count = 0
        const players = mejs.players
        const player = Object.keys(players).map(k => {
          if (k.indexOf('mep_') > -1) {
            return players[k]
          }
        })
        return player
      },

      getSourceId($el) {
        const preText = 'master_files/'
        const clipSource = $el.data('clipSource')
        const sourceId = clipSource.substring(clipSource.indexOf(preText) + preText.length)
        return sourceId
      },

      handleClick(e) {
        const dataSet = e.target.dataset;

        this.updateStyles(e.target);

        // Same media object/file?
        if (this.sameSource(e.target)) {
          // Update playlist item start and end times
          this.startEndTimes.start = parseInt(dataSet.clipStartTime, 10)/1000;
          this.startEndTimes.end = parseInt(dataSet.clipEndTime, 10)/1000;
          // Apply start time to player
          this.player.setCurrentTime(this.startEndTimes.start);
        } else {
          console.log('not the same');
          // Remove old player
          mejs4AvalonPlayer.removePlayer()
          // Instantiate new player
          this.ajaxGetNewMedia(e.target)
        }
      },

      ajaxGetNewMedia(el) {
        const dataSet = el.dataset;

        $.ajax({
          url: `http://localhost:3000/media_objects/${dataSet.mediaObjectId}/section/${dataSet.masterFileId}/stream.js`,
          dataType: 'json'
        }).done((response) => {
          console.log('response', response);
          mejs4AvalonPlayer.currentStreamInfo = response;
          mejs4AvalonPlayer.mediaType = this.mejsUtility.getMediaType(response.is_video);
          mejs4AvalonPlayer.createNewPlayer();
        }).fail((error) => {
          console.log('error', error);
        })
      },

      handleTimeUpdate() {
        console.log('time: ', this.playlistItemsObj.player.getCurrentTime());
        // TODO: stop playback at stop time
      },

      sameSource(el) {
        return this.currentStreamInfo.id === this.getSourceId($(el))
      },

      /**
       * Helper jQuery object for side playlist element which is used a few times in this class
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

      /**
       * Update styles on the playlist items list
       * @function updateStyles
       * @param  {HTMLElement} el The <a> item HTML element clicked
       * @return {void}
       */
      updateStyles(el) {
        const nodeItems = this.$sidePlaylist[0].getElementsByTagName('li')
        let array = [ ...nodeItems]
        let clickedEl = el.parentNode
        const arrowNode = document.createElement('i')

        arrowNode.className = `fa fa-arrow-circle-right`

        // Loop through all children list items
        array.forEach(li => {
          const children = [...li.children]
          let arrow = children.find(e => e.nodeName === 'I')
          // Remove styles
          li.classList.remove('now_playing')
          li.classList.remove('queue')
          if (arrow) {
            li.removeChild(arrow)
          }
          // Conditionally add styles to the item clicked
          if (li === clickedEl) {
            li.insertBefore(arrowNode, el)
            li.classList.add('now_playing')
          } else {
            li.classList.add('queue')
          }
        })
      }
    }

});
