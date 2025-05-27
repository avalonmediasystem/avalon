/* 
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

/**
 * Get the current active structure item(s) from DOM
 * @param {Boolean} checkSection flag to indicate current section as active
 * @returns {Object} active track information
 */
function getActiveItem(checkSection = true) {
  let currentPlayer = document.getElementById('iiif-media-player');
  let duration = currentPlayer.player.duration();
  let currentStructureItem = $('li[class="ramp--structured-nav__list-item active"]');
  let currentSection = $('div[class="ramp--structured-nav__section active"]');

  if (currentStructureItem?.length > 0) {
    /**
     * When there's an active timespan in the structured navigation
     * use its details to populate the create timeline and add to
     * playlist optioins
     */
    let label = currentStructureItem[0].dataset.label;
    let activeCanvasOnly = currentSection.parent().is(currentStructureItem);
    // When canvas item is the only active structure item, add it as an option
    if (activeCanvasOnly) {
      let { mediafrag, label } = currentSection[0].dataset;
      let [itemId, timeHash] = mediafrag.split('#t=');
      return {
        label,
        times: {
          begin: parseFloat(timeHash.split(',')[0]) || 0,
          end: parseFloat(timeHash.split(',')[1]) || duration
        },
        tags: ['current-track', 'current-section'],
        streamId: itemId.split('/').pop(),
        sectionLabel: label,
      };
    }

    // When structure has an active timespan child
    if (currentStructureItem.find('a').length > 0) {
      let item = currentStructureItem.find('a')[0];
      let timeHash = item.hash.split('#t=').pop();
      let times = {
        begin: parseFloat(timeHash.split(',')[0]) || 0,
        end: parseFloat(timeHash.split(',')[1]) || duration
      };
      let streamId = item.pathname.split('/').pop();
      return {
        label,
        times,
        tags: ['current-track'],
        streamId,
        sectionLabel: currentSection[0].dataset.label,
      };
    }
  } else if (currentSection?.length > 0 && checkSection) {
    /** When the structured navigation doesn't have an active timespan
     * get the current active section to populate the timeline and add
     * to playlist options */
    let { mediafrag, label } = currentSection[0].dataset;
    let [itemId, timeHash] = mediafrag.split('#t=');
    return {
      label,
      times: {
        begin: currentPlayer.player.currentTime(),
        end: duration,
      },
      tags: ['current-section'],
      streamId: itemId.split('/').pop(),
      sectionLabel: label,
    };
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
  let currentSection = $('div[class="ramp--structured-nav__section active"]');
  let activeItem = getActiveItem();
  let streamId = '';

  if (activeItem != undefined) {
    streamId = activeItem.streamId;
    scopes.push({
      ...activeItem,
      tracks: trackCount,
    });
  }

  let parent = currentStructureItem.closest('ul').closest('li');
  if (parent.length === 0) {
    let begin = 0;
    let end = activeItem.times.end;
    scopes[0].times = { begin: 0, end: end };
  }
  while (parent.length > 0) {
    let next = parent.closest('ul').closest('li');
    let begin = 0;
    let end = '';
    let tracks = parent.find('li a');
    trackCount = tracks.length;
    // Only assign begin/end when structure item is a subsection, not a top level section
    if (next.length >= 0) {
      begin = parseFloat(tracks[0].hash.split('#t=').reverse()[0].split(',')[0]) || 0;
      end = parseFloat(tracks[trackCount - 1].hash.split('#t=').reverse()[0].split(',')[1]) || '';
    }
    streamId = tracks[0].pathname.split('/').reverse()[0];
    let label = parent[0].dataset.label;
    scopes.push({
      label: label,
      tracks: trackCount,
      times: { begin, end },
      tags: [], 
    });
    parent = next;
  }
  // mark the outermost item representing the current section
  if (currentStructureItem !== currentSection) {
    scopes.push({
      label: currentSection[0].dataset.label,
      times: { begin: 0, end: parseFloat(currentSection[0].dataset.mediafrag.split('#t=').reverse()[0].split(',')[1]) || '' },
      tags: ['current-section']
    });
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
 * Convert time from hh:mm:ss.ms/mm:ss.ms string format to int
 * @param {String} time convert time from string to int
 */
function timeToS(time) {
  var time_split = time.split(':').reverse(),
    seconds = time_split[0],
    minutes = time_split[1],
    hours = time_split[2];
  var hoursInS = hours != undefined ? parseInt(hours) * 3600 : 0;
  var minutesInS = minutes != undefined ? parseInt(minutes) * 60 : 0;
  var secondsNum = seconds === '' ? 0.0 : parseFloat(seconds);
  var timeSeconds = hoursInS + minutesInS + secondsNum;
  return timeSeconds;
}

/** Collapse multi item check for creating a playlist item for each structure item of
 * the selected scope
 */
function collapseMultiItemCheck() {
  $('#multiItemCheck').collapse('show');
  $('#moreDetails').collapse('hide');
}

/** Collapse title and description forms */
function collapseMoreDetails() {
  if (!$('#moreDetails').hasClass('show')) {
    $('#moreDetails').collapse('show');
    $('#multiItemCheck').collapse('hide');
    // When the title field is empty fill it with either
    // current track or current section name
    if ($('#playlist_item_title').val() == '') {
      $('#playlist_item_title').val(
        $('#current-track-name').text() || $('#current-section-name').text()
      );
    }
  }
}

/**
 * Enable or disable the 'Current Track' option based on the current time of
 * the player. When the current time is not included within an active timespan
 * disable the option otherwise enable it.
 * @param {Object} activeTrack JSON object for the active timespans
 * @param {Number} currentTime player's playhead position
 * @param {Boolean} isPlaying flag to inidicate media is playing or not
 * @param {String} sectionTitle name of the current section
 */
function disableEnableCurrentTrack(activeTrack, currentTime, isPlaying, sectionTitle) {
  // Return when add to playlist form is not visible
  let playlistForm = $('#add_to_playlist')[0];
  if (!playlistForm) {
    return;
  }
  let title = sectionTitle;
  if (activeTrack != undefined) {
    streamId = activeTrack.streamId;
    let { label, times, sectionLabel } = activeTrack;
    // Update starttime when media is not playing
    let starttime = isPlaying ? times.begin : currentTime || times.begin;
    $('#playlist_item_start').val(createTimestamp(starttime, true));
    $('#playlist_item_end').val(createTimestamp(times.end, true));
    title = `${sectionLabel} - ${label}`;
    $('#current-track-name').text(title);
    // When player's currentTime is in between the activeTrack's begin and
    // end times, enable the current track option
    if (times.begin <= starttime && starttime <= times.end) {
      $('#playlistitem_scope_track')[0].disabled = false;
      $('#current-track-text').removeClass('disabled-option');
      $('#playlistitem_scope_track').closest('label').css('cursor', 'pointer');
    }
  } else {
    // When activeTrack is undefined, disable the current track option
    $('#playlistitem_scope_track')[0].disabled = true;
    $('#current-track-name').text('');
    $('#current-track-text').addClass('disabled-option');
    $('#playlistitem_scope_track').closest('label').css('cursor', 'not-allowed');
    if ($('#playlistitem_scope_track')[0].checked) {
      $('#moreDetails').collapse('hide');
      $('#playlistitem_scope_track').prop('checked', false);
    }
  }
  if (sectionTitle != undefined) {
    $('#playlist_item_title').val(title);
  }
}

/** AJAX request for add to playlist for submission for playlist item for
 * a selected clip
 */
function addPlaylistItem(playlistId, masterfileId, starttime, endtime) {
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
    success: function (res) {
      handleAddSuccess(res);
    },
    error: function (err) {
      handleAddError(err);
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
    success: function (res) {
      handleAddSuccess(res);
    },
    error: function (err) {
      handleAddError(err);
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
  $('#playlist_item_description').val('');
  $('#playlist_item_title').val('');
  $('input[name="post[playlistitem_scope]"]').prop('checked', false);
  $('#playlistitem_scope_structure').prop('checked', true);
  $('#moreDetails').collapse('hide');
  $('#multiItemCheck').collapse('hide');
}

/** Reset add to playlist panel when alert is closed */
function closeAlert() {
  $('#add_to_playlist_alert').slideUp();
  $('#add_to_playlist_form_group').slideDown();
  // Set default selection in options list when alert is closed
  if ($('#playlistitem_scope_track')[0].disabled) {
    $('#playlistitem_scope_section').prop('checked', true);
  } else {
    $('#playlistitem_scope_track').prop('checked', true);
  }
}

/** Refresh stream token by reloading active m3u8 */
function m3u8Reload() {
  player = document.getElementById('iiif-media-player');
  fetch(player.player.currentSources()[0]["src"]);
};
