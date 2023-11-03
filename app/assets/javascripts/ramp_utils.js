/* 
 * Copyright 2011-2023, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 * 
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software distributed
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
*/

/** Get the current active structure item from DOM */
function getActiveItem() {
  let currentPlayer = document.getElementById('iiif-media-player');
  let duration = currentPlayer.player.duration();
  let currentStructureItem = $('li[class="ramp--structured-nav__list-item active"]');
  let currentSection = $('div[class="ramp--structured-nav__section active"]');

  if(currentStructureItem?.length > 0) {
    /**
     * When there's an active timespan in the structured navigation
     * use its details to populate the create timeline and add to
     * playlist optioins
     */
    let label = currentStructureItem[0].dataset.label;
    let activeCanvasOnly = currentSection.parent().is(currentStructureItem);
    // When canvas item is the only active structure item, add it as an option
    if(activeCanvasOnly) {
      let { mediafrag, label } = currentSection[0].dataset;
      let [ itemId, timeHash ] = mediafrag.split('#t=');
      return { 
        label, 
        times: {
          begin: parseFloat(timeHash.split(',')[0]) || 0,
          end: parseFloat(timeHash.split(',')[1]) || duration
        },
        tags: ['current-track', 'current-section'],
        streamId: itemId.split('/').pop()
      }
    }
  
    // When structure has an active timespan child
    if(currentStructureItem.find('a').length > 0) {
      let item = currentStructureItem.find('a')[0];
      let timeHash = item.hash.split('#t=').pop();
      let times = {
        begin: parseFloat(timeHash.split(',')[0]) || 0,
        end: parseFloat(timeHash.split(',')[1]) || duration
      }
      let streamId = item.pathname.split('/').pop();
      return { label, times, tags: ['current-track'], streamId };
    }
  } else if (currentSection?.length > 0) {
    /** When the structured navigation doesn't have an active timespan
     * get the current active section to populate the timeline and add
     * to playlist options */
    let label = currentSection[0].dataset.label;
    return {
      label,
      times: {
        begin: currentPlayer.player.currentTime(),
        end: duration,
      },
      tags: ['current-section'],
      streamId: '',
    }
  }
}

/**
 * Get new timeline scopes for active section
 * @function getTimelineScopes
 * @returns {object} { [{label: string, tracks: int, times: { begin: float, end: float }, tag: string }], streamId: string }
 * {[{ scope label, number of tracks, { start, end times of the mediafragment }, tag }], masterfile id }
 */
function getTimelineScopes() {
  let scopes = new Array();
  let trackCount = 1;
  let currentStructureItem = $('li[class="ramp--structured-nav__list-item active"]') ||
  $('div[class="ramp--structured-nav__section active"]');
  let activeItem = getActiveItem();
  let streamId = '';

  if(activeItem != undefined) {
    streamId = activeItem.streamId;
    scopes.push({
      label: activeItem.label,
      tracks: trackCount,
      times: activeItem.times,
      tags: activeItem.tags,
    });
  }

  let parent = currentStructureItem.closest('ul').closest('li');
  while (parent.length > 0) {
    let next = parent.closest('ul').closest('li');
    let tracks = parent.find('li a');
    trackCount = tracks.length;
    let begin = parseFloat(tracks[0].hash.split('#t=').reverse()[0].split(',')[0]) || 0;
    let end = parseFloat(tracks[trackCount - 1].hash.split('#t=').reverse()[0].split(',')[1]) || '';
    streamId = tracks[0].pathname.split('/').reverse()[0];
    let label = parent[0].dataset.label;
    scopes.push({
      label: label,
      tracks: trackCount,
      times: { begin, end },
      tags: next.length == 0 ? ['current-section'] : [], // mark the outermost item representing the current section
    });
    parent = next;
  }
  return { scopes: scopes.reverse(), streamId };
}

/**
 * Parse time in seconds to hh:mm:ss.ms format
 * @param {Number} secTime time in seconds
 * @param {Boolean} showHrs flag indicating for showing hours
 * @returns 
 */
function createTimestamp(secTime, showHrs) {
  let hours = Math.floor(secTime / 3600);
  let minutes = Math.floor((secTime % 3600) / 60);
  let seconds = secTime - minutes * 60 - hours * 3600;
  if (seconds > 59.9) {
    minutes = minutes + 1;
    seconds = 0;
  }
  seconds = parseInt(seconds);

  let hourStr = hours < 10 ? `0${hours}` : `${hours}`;
  let minStr = minutes < 10 ? `0${minutes}` : `${minutes}`;
  let secStr = seconds < 10 ? `0${seconds}` : `${seconds}`;

  let timeStr = `${minStr}:${secStr}`;
  if (showHrs || hours > 0) {
    timeStr = `${hourStr}:${timeStr}`;
  }
  return timeStr;
}

/**
 * Update section and lti section share links and embed code when switching sections
 * @function updateShareLinks
 * @return {void}
 */
function updateShareLinks (e) {
  const sectionShareLink = e.detail.link_back_url;
  const ltiShareLink = e.detail.lti_share_link;
  const embedCode = e.detail.embed_code;
  $('#share-link-section')
    .val(sectionShareLink)
    .attr('placeholder', sectionShareLink);
  $('#ltilink-section')
    .val(ltiShareLink)
    .attr('placeholder', ltiShareLink);
  $('#embed-part').val(embedCode);
}

/** Collapse multi item check for creating a playlist item for each structure item of
 * the selected scope
 */
function collapseMultiItemCheck () {
  $('#multiItemCheck').collapse('show');
  $('#moreDetails').collapse('hide');
}

/** Collapse title and description forms */
function collapseMoreDetails() {
  $('#moreDetails').collapse('show');
  $('#multiItemCheck').collapse('hide');
  let currentTrackName = $('#current-track-name').text();
  $('#playlist_item_title').val(currentTrackName);
}

/** AJAX request for add to playlist for submission for playlist item for 
 * a selected clip
 */
function addPlaylistItem (playlistId, masterfileId, starttime, endtime) {
  $.ajax({
    url: '/playlists/' + playlistId + '/items',
    type: 'POST',
    data: {
      playlist_item: {
        master_file_id: masterfileId,
        title: $('#playlist_item_title').val(),
        comment: $('#playlist_item_description').val(),
        start_time: starttime,
        end_time: endtime,
      }
    },
    success: function(res) {
      handleAddSuccess(res);
    },
    error: function(err) {
      handleAddError(err)
    }
  });
}

/** AJAX request for add to playlist for submission for playlist items for 
 * section(s)
 */
function addToPlaylist(playlistId, scope, masterfileId, moId) {
  $.ajax({
    url: '/media_objects/' + moId + '/add_to_playlist',
    type: 'POST',
    data: {
      post: {
        masterfile_id: masterfileId,
        playlist_id: playlistId,
        playlistitem_scope: scope
      }
    },
    success: function(res) {
      handleAddSuccess(res);
    },
    error: function(err) {
      handleAddError(err)
    }
  });
}

/** Show success message for add to playlist */
function handleAddSuccess(response) {
  let alertEl = $('#add_to_playlist_alert');

  alertEl.removeClass('alert-danger');
  alertEl.addClass('alert-success');
  alertEl.find('#add_to_playlist_result_message').html(response.message);

  alertEl.slideDown();
  $('#add_to_playlist_form_group').slideUp();
  resetAddToPlaylistForm();
}

/** Show error message for add to playlist */
function handleAddError(error) {
  let alertEl = $('#add_to_playlist_alert');
  let message = error.statusText || 'There was an error adding to playlist';

  if (error.responseJSON && error.responseJSON.message) {
    message = error.responseJSON.message.join('<br/>');
  }

  alertEl.removeClass('alert-success');
  alertEl.addClass('alert-danger add_to_playlist_alert_error');
  alertEl.find('#add_to_playlist_result_message').html('ERROR: ' + message);

  alertEl.slideDown();
  $('#add_to_playlist_form_group').slideUp();
  resetAddToPlaylistForm();
}

/** Reset add to playlist form */
function resetAddToPlaylistForm() {
  $('#playlist_item_description').value = '';
  $('#playlist_item_title').value = '';
  $('input[name="post[playlistitem_scope]"]').prop('checked', false);
  $('#playlistitem_scope_structure').prop('checked', false);
  $('#moreDetails').collapse('hide');
  $('#multiItemCheck').collapse('hide');
}

/** Reset add to playlist panel when alert is closed */
function closeAlert() {
  $('#add_to_playlist_alert').slideUp();
  $('#add_to_playlist_form_group').slideDown();
}
