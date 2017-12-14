/**
 * Markers helper class...currently being defined.
 * @class MEJSMarkersHelper
 */
class MEJSMarkersHelper {
  constructor() {
    this.$accordion = $('#accordion');
  }

  /**
   * Add event listeners for elements in Markers table rows
   * @function addMarkersTableListeners
   * @param player Instance of player
   * @return {void}
   */
  addMarkersTableListeners() {
    const t = this;
    let addMarkerObj = t.addMarkerObj;
    const player = mejs4AvalonPlayer.player;
    const $markers = $('#markers');
    const $alertError = $('#marker_item_edit_alert');
    let originalMarkerValues = {};

    // Marker title click; play from marker offset time
    $markers.find('a.marker_title').on('click', e => {
      const offset = $(e.target)
        .parents('tr')
        .data('offset');
      player.setCurrentTime(offset);
    });

    // Edit button click
    $markers.find('button[name="edit_marker"]').on('click', e => {
      const $row = $(e.target).parents('tr');
      const markerId = $row.data('markerId');
      const offset = mejs.Utils.convertSMPTEtoSeconds(
        $row.find('input[name="offset_' + markerId + '"]').val()
      );

      t.disableButtons($row, true);
      $(e.target)
        .parents('tr')
        .addClass('is-editing');
      // Track original marker offset value of edited row
      originalMarkerValues[markerId] = offset;
    });

    // Cancel button click
    $markers.find('button[name="marker_edit_cancel"]').on('click', e => {
      let $row = $(e.target).parents('tr');
      const markerId = $row.data('markerId');

      t.disableButtons($row, false);
      $alertError.slideUp();
      $row.removeClass('is-editing');

      // Remove original marker offset value
      delete originalMarkerValues[markerId];
    });

    // Delete button click
    $markers.find('button[name="delete_marker"]').on('click', e => {
      let $button = $(e.currentTarget);
      let markerId = $button[0].dataset.markerId;
      let confirmButtonId = 'delete_marker_confirm_' + markerId;
      let cancelButtonId = 'delete_marker_cancel_' + markerId;
      let content = `<p>Are you sure?</p>
                      <button id="${confirmButtonId}" class="btn btn-xs btn-danger">Submit</button>
                      <button id="${cancelButtonId}" class="btn btn-xs btn-primary">No, cancel</button>`;

      // Show popover confirmation
      $button.popover({
        container: '#popover-container-' + $button[0].dataset.markerId,
        content: content,
        html: true,
        placement: 'top'
      });
      $button.popover('show');

      // Delete confirm click
      $('#' + confirmButtonId).on('click', e => {
        $.ajax({
          url: '/avalon_marker/' + markerId,
          type: 'POST',
          data: {
            utf: '✓',
            _method: 'delete'
          }
        })
          .done(response => {
            const row = $('#markers')[0].querySelector(
              'tr[data-marker-id="' + response.id + '"]'
            );
            const playlistIds = this.getCurrentPlaylistIds();

            $button.popover('destroy');
            // Remove from list
            row.parentNode.removeChild(row);
            // Update visual markers in player's time rail
            this.getMarkers(
              playlistIds.playlistId,
              playlistIds.playlistItemId
            ).then(response => {
              this.updateVisualMarkers(response);
            });
          })
          .fail(error => {
            console.log('error', error);
          });
      });

      // Delete cancel click
      $('#' + cancelButtonId).on('click', e => {
        $button.popover('destroy');
      });
    });

    // Save button click
    $markers.find('button[name="save_marker"]').on('click', e => {
      const $tr = $(e.target).parents('tr');
      const markerId = $tr.data('markerId');
      const marker = {
        title: $tr.find('input[name="title_' + markerId + '"]').val(),
        start_time: $tr.find('input[name="offset_' + markerId + '"]').val(),
        marker_edit_save: ''
      };

      // Hide old error messages
      $alertError.hide();

      $.ajax({
        url: '/avalon_marker/' + markerId,
        type: 'POST',
        data: {
          utf: '✓',
          _method: 'patch',
          marker: marker
        }
      })
        .done(response => {
          const playlistIds = this.getCurrentPlaylistIds();

          // Update visual markers in player's time rail
          this.getMarkers(
            playlistIds.playlistId,
            playlistIds.playlistItemId
          ).then(response => {
            this.updateVisualMarkers(response);
          });

          // Remove original marker offset value
          // TODO: Remember why I originally did this?
          delete originalMarkerValues[markerId];

          // Rebuild markers table with updated values
          t.rebuildMarkersTable();
        })
        .fail(error => {
          // Display error message
          const responseText = JSON.parse(error.responseText);
          const msg =
            responseText.errors[0] ||
            'There was an unknown error updating marker';

          $alertError.find('p').text(msg);
          $alertError.slideDown();
        });
    });
  }

  /**
   * Get HTML markup for accordion panel sections on Playlist Items page
   * @param  {number} playlistId
   * @param  {number} playlistItemId
   * @param  {string} panelSection Panel section string corresponding to the endpoint ie. ('markers', 'source_details', 'related_items')
   * @return {Promise} Resolves to either a block of markup or an empty string.
   */
  ajaxPlaylistItemsHTML(playlistId, playlistItemId, panelSection) {
    return new Promise((resolve, reject) => {
      $.ajax({
        url: `/playlists/${playlistId}/items/${playlistItemId}/${panelSection}`
      })
        .done(response => {
          resolve(response);
        })
        .fail(error => {
          reject('');
        })
        .always(() => {
          // Turn off spinner
          this.spinnerToggle();
        });
    });
  }

  /**
   * Build the markers config object which the Mediaelement Markers plugin requires
   * when building an instance of the player.
   * @function buildMarkersConfig
   * @param  {Array} markers Array of marker start times
   * @return {Object} Configuration object (https://github.com/mediaelement/mediaelement-plugins/blob/master/docs/markers.md)
   */
  buildMarkersConfig(markers) {
    return {
      markerColor: '#777',
      markers: markers
    };
  }

  /**
   * Disable sibling table row buttons when editing a row
   * @function disableButtons
   * @param  {Object} $row jQuery object of current table row being edited
   * @param  {boolean} doDisable Enable or disable sibling buttons?
   * @return {void}
   */
  disableButtons($row, doDisable) {
    const addMarkerObj = this.addMarkerObj;
    let $siblings = $row.siblings();

    $siblings.find('button[name="edit_marker"]').prop({ disabled: doDisable });
    $siblings
      .find('button[name="delete_marker"]')
      .prop({ disabled: doDisable });
  }

  /**
   * Get playlist item markers if a playlist id is specified, otherwise return an empty array
   * @function getMarkers
   * @param {number} playlistId Id of playlist
   * @param {number} playlistItemId Id of playlist item
   * @return {Array} Array of marker start times
   */
  getMarkers(playlistId, playlistItemId) {
    return new Promise((resolve, reject) => {
      // Check if a playlist item is specified, because playlist items use markers
      // and we'll need to grab markers from the playlist item
      if (playlistId && playlistItemId) {
        const playlistItem = this.playlistItem;
        let markers = [];

        $.ajax({
          url:
            '/playlists/' + playlistId + '/items/' + playlistItemId + '.json',
          dataType: 'json'
        })
          .done(response => {
            if (response.message) {
              //TODO: display error message somehow (500 or 401)
            } else if (response.markers && response.markers.length > 0) {
              markers = response.markers.map(marker => {
                return marker.start_time;
              });
            }
            resolve(markers);
          })
          .fail(error => {
            reject([]);
          });
      } else {
        // No playlist item, therefore no markers needed
        resolve([]);
      }
    });
  }

  /**
   * Helper method to get current playlist id and current playlist item id
   * as currently represented in the DOM (playlist items list)
   * @function getCurrentPlaylistIds
   * @return {Object} Helper object returning playlist id and playlist item id as key/value pairs
   */
  getCurrentPlaylistIds() {
    const $nowPlaying = $('#right-column').find(
      '.side-playlist li.now_playing'
    );
    return {
      playlistId: $nowPlaying.find('a').data('playlistId'),
      playlistItemId: $nowPlaying.data('playlistItemId')
    };
  }

  /**
   * Re-build the markers table after an add or edit
   * @function rebuildMarkersTable
   * @return {void}
   */
  rebuildMarkersTable() {
    const t = this;
    const playlistIds = this.getCurrentPlaylistIds();

    // Grab new html to use
    t
      .ajaxPlaylistItemsHTML(
        playlistIds.playlistId,
        playlistIds.playlistItemId,
        'markers'
      )
      .then(response => {
        // Insert the fresh HTML table
        $('#markers').replaceWith(response);
        // Add event listeners to newly created row
        t.addMarkersTableListeners();
        // hide marker sections if no markers (first row is header)
        if ($('#markers').find('tr').length === 1) {
          $('#markers_section').collapse('hide')
          $('#markers_heading').hide()
        } else {
          $('#markers_heading').show()
        }
      })
      .catch(err => {
        console.log(err);
      });
  }

  spinnerToggle(on) {
    if (on) {
      this.$accordion.addClass('spinner');
    } else {
      this.$accordion.removeClass('spinner');
    }
  }

  /**
   * Update markers in Mediaelement player's time rail by hooking into the Mediaelement Markers plugin
   * @function updateVisualMarkers
   * @param {Array} markers Array of marker start times
   * @return {void}
   */
  updateVisualMarkers(markers) {
    const t = this;
    const player = mejs4AvalonPlayer.player;
    player.options.markers = markers;

    // Directly delete current markers from the player UI
    let currentMarkerEls = player.controls.getElementsByClassName(
      player.options.classPrefix + 'time-marker'
    );
    while (currentMarkerEls[0]) {
      currentMarkerEls[0].parentNode.removeChild(currentMarkerEls[0]);
    }

    // Call methods on the MEJS4 markers plugin to re-build markers and apply to the player
    player.buildmarkers(player, player.controls, undefined, player.media);
    player.setmarkers(player.controls);
  }
}
