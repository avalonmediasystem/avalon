class MEJSMarkersHelper {
  /**
   * Build the markers config object which the Mediaelement Markers plugin requires
   * when building an instance of the player.
   * @param  {Array} markers Array of marker start times
   * @return {Object} Configuration object (https://github.com/mediaelement/mediaelement-plugins/blob/master/docs/markers.md)
   */
  buildMarkersConfig (markers) {
    return {
      markerColor: '#fff',
      markers: markers
    }
  }

  /**
   * Get playlist item markers if a playlist id is specified, otherwise return an empty array
   * @function getMarkers
   * @param {number} playlistId Id of playlist
   * @param {number} playlistItemId Id of playlist item
   * @return {Array} Array of marker start times
   */
  getMarkers (playlistId, playlistItemId) {
    return new Promise((resolve, reject) => {

      // Check if a playlist item is specified, because playlist items use markers
      // and we'll need to grab markers from the playlist item
      if (playlistId && playlistItemId) {
        const playlistItem = this.playlistItem
        let markers = []

        $.ajax({
          url: '/playlists/' + playlistId + '/items/' + playlistItemId + '.json',
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
          resolve(markers)
        }).fail((error) => {
          reject([])
        });
      } else {
        // No playlist item, therefore no markers needed
        resolve([])
      }
    })
  }

  /**
   * Update markers in the UI on the player by hooking into Mediaelement Markers plugin
   * @function updateVisualMarkers
   * @param {Array} markers Array of marker start times
   * @return {void}
   */
  updateVisualMarkers (markers) {
    const t = this;
    t.player.options.markers = markers;

    // Directly delete current markers from the player UI
    let currentMarkerEls = t.player.controls.getElementsByClassName(t.player.options.classPrefix + 'time-marker');
    while(currentMarkerEls[0]) {
      currentMarkerEls[0].parentNode.removeChild(currentMarkerEls[0]);
    }

    // Call methods on the MEJS4 markers plugin to re-build markers and apply to the player
    t.player.buildmarkers(t.player, t.player.controls, undefined, t.player.media);
    t.player.setmarkers(t.player.controls);
  }
}
