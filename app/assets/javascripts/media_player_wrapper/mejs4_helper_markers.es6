class MEJSMarkersHelper {
  /**
   * Get any playlist item markers if a playlist item is specified
   * @function getMarkers
   * @return {obj} obj - Markers plugin specific configuration
   */
  getMarkers (resolve, reject) {
    let returnObj = {}
    let markersConfig = {
      markerColor: '#fff', // Optional : Specify the color of the marker
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
}
