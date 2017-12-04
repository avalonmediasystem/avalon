class MEJSPlaylistsHelper {
  constructor() {
    this.currentSourceId = null
    this.player = null
  }

  addClickListeners() {
    const $playlistsEl = $('#right-column').find('.side-playlist')

    if ($playlistsEl.length > 0) {
      // Handle click on entire Playlists right column area
      $playlistsEl[0].addEventListener('click', (e) => {
        // Only handle clicks on <a> elements
        if (e.target.nodeName === 'A') {
          this.handleClick(e)
        }
      });
    }
  }

  getPlayer() {
    let count = 0
    const players = mejs.players
    const player = Object.keys(players).map(k => {
      if (k.indexOf('mep_') > -1) {
        return players[k]
      }
    })
    return player
  }

  getSourceId($el) {
    const preText = 'master_files/'
    const clipSource = $el.data('clipSource')
    const sourceId = clipSource.substring(clipSource.indexOf(preText) + preText.length)
    return sourceId
  }

  handleClick(e) {
    // Same media object/file?
    console.log('mejs4AvalonPlayer.currentStreamInfo.id', mejs4AvalonPlayer.currentStreamInfo.id)
    if (this.sameSource(e.target)) {
      // Update the current time
      mejs4AvalonPlayer.player.setCurrentTime(13)
    } else {
      // Remove click listener
      // Remove old player
      // Instantiate new player
    }

    // Somehow need to determine start stop points and that this action
    // is being caused by the playlists clicks
  }

  sameSource(el) {
    return mejs4AvalonPlayer.currentStreamInfo.id === this.getSourceId($(el))
  }
}
