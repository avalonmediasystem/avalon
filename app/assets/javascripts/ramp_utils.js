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
  let currentPlayer = getById('iiif-media-player');
  let duration = currentPlayer.player.duration();
  let currentStructureItem = query('li[class="ramp--structured-nav__tree-item active"]');
  // Get active section with class starting with 'ramp--structured-nav__section' and ending with 'active'
  let activeSection = query('div[class^="ramp--structured-nav__section"][class$="active"]');
  // Get parent list item for the active section
  let currentSection = activeSection ? activeSection.closest('li') : null;
  if (currentStructureItem) {
    /**
     * When there's an active timespan in the structured navigation
     * use its details to populate the create timeline and add to
     * playlist options
     */
    let label = currentStructureItem.dataset.label;

    // When structure has an active timespan child
    if (queryAll('a', currentStructureItem).length > 0) {
      let item = query('a', currentStructureItem);
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
        sectionLabel: currentSection ? currentSection.dataset.label : '',
      };
    }
  } else if (activeSection && currentSection && checkSection) {
    /** When the structured navigation doesn't have an active timespan
     * get the current active section to populate the timeline and add
     * to playlist options */
    let { mediafrag } = activeSection.dataset;
    let { label } = currentSection.dataset;
    let [itemId, _] = mediafrag.split('#t=');
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
  let currentStructureItem = query('li[class="ramp--structured-nav__tree-item active"]') ||
    query('div[class^="ramp--structured-nav__section"][class$="active"]');
  // Get active section with class starting with 'ramp--structured-nav__section' and ending with 'active'
  let activeSection = query('div[class^="ramp--structured-nav__section"][class$="active"]');
  // Get parent list item for the active section
  let currentSection = activeSection ? activeSection.closest('li') : null;
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
  if (!parent) {
    let end = activeItem.times.end;
    scopes[0].times = { begin: 0, end: end };
  }
  while (parent) {
    let next = parent.closest('ul').closest('li');
    let begin = 0;
    let end = '';
    let tracks = queryAll('li a', parent);
    trackCount = tracks.length;
    // Only assign begin/end when structure item is a subsection, not a top level section
    if (next) {
      begin = parseFloat(tracks[0].hash.split('#t=').reverse()[0].split(',')[0]) || 0;
      end = parseFloat(tracks[trackCount - 1].hash.split('#t=').reverse()[0].split(',')[1]) || '';
    }
    streamId = tracks[0].pathname.split('/').reverse()[0];
    let label = parent.dataset.label;
    scopes.push({
      label: label,
      tracks: trackCount,
      times: { begin, end },
      // mark the outermost item representing the current section
      tags: parent == currentSection ? ['current-section'] : [],
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
  const multiItemCheck = getById('multiItemCheck');
  const moreDetails = getById('moreDetails');
  if (multiItemCheck) showOrCollapse(multiItemCheck, true);
  if (moreDetails && moreDetails.classList.contains('show')) {
    showOrCollapse(moreDetails, false);
  }
}

/** Collapse title and description forms */
function collapseMoreDetails() {
  const moreDetails = getById('moreDetails');
  if (moreDetails && !moreDetails.classList.contains('show')) {
    showOrCollapse(moreDetails, true);

    const multiItemCheck = getById('multiItemCheck');
    if (multiItemCheck && multiItemCheck.classList.contains('show')) {
      showOrCollapse(multiItemCheck, false);
    }

    // When the title field is empty fill it with either
    // current track or current section name
    const playlistItemTitle = getById('playlist_item_title');
    const currentTrackName = getById('current-track-name');
    const currentSectionName = getById('current-section-name');
    playlistItemTitle.value = (currentTrackName ? currentTrackName.textContent : '')
      || (currentSectionName ? currentSectionName.textContent : '');
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
  let playlistForm = getById('add_to_playlist');
  if (!playlistForm) {
    return;
  }
  let title = sectionTitle;
  const trackRadio = getById('playlistitem_scope_track');
  const trackText = getById('current-track-text');
  const trackName = getById('current-track-name');
  if (activeTrack != undefined) {
    streamId = activeTrack.streamId;
    let { label, times, sectionLabel } = activeTrack;
    // Update starttime when media is not playing
    let starttime = isPlaying ? times.begin : currentTime || times.begin;
    getById('playlist_item_start').value = createTimestamp(starttime, true);
    getById('playlist_item_end').value = createTimestamp(times.end, true);
    title = `${sectionLabel} - ${label}`;
    trackName.textContent = title;
    // When player's currentTime is in between the activeTrack's begin and
    // end times, enable the current track option
    if (times.begin <= starttime && starttime <= times.end) {
      if (trackRadio) {
        trackRadio.disabled = false;
        if (trackRadio.closest('label')) trackRadio.closest('label').style.cursor = 'pointer';
      }
      if (trackText) trackText.classList.remove('disabled-option');
    }
  } else {
    // When activeTrack is undefined, disable the current track option
    if (trackRadio) {
      trackRadio.disabled = true;
      if (trackRadio.closest('label')) trackRadio.closest('label').style.cursor = 'not-allowed';

      if (trackRadio.checked) {
        const moreDetails = getById('moreDetails');
        if (moreDetails) showOrCollapse(moreDetails, false);
        trackRadio.checked = false;
      }
    }
    if (trackName) trackName.textContent = '';
    if (trackText) trackText.classList.add('disabled-option');
  }
  if (sectionTitle != undefined) {
    getById('playlist_item_title').value = title;
  }
}

/** Fetch request for add to playlist for submission for playlist item for
 * a selected clip
 */
function addPlaylistItem(playlistId, masterfileId, starttime, endtime) {
  const formData = new FormData();
  formData.append('playlist_item[master_file_id]', masterfileId);
  formData.append('playlist_item[title]', getById('playlist_item_title').value);
  formData.append('playlist_item[comment]', getById('playlist_item_description').value);
  formData.append('playlist_item[start_time]', starttime);
  formData.append('playlist_item[end_time]', endtime);

  fetch('/playlists/' + playlistId + '/items', {
    method: 'POST',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': query('meta[name="csrf-token"]').content
    },
    body: formData
  })
    .then(response => response.json())
    .then(res => {
      handleAddSuccess(res);
    })
    .catch(err => {
      handleAddError(err);
    });
}

/** Fetch request for add to playlist for submission for playlist items for
 * section(s)
 */
function addToPlaylist(playlistId, scope, masterfileId, moId) {
  const formData = new FormData();
  formData.append('post[masterfile_id]', masterfileId);
  formData.append('post[playlist_id]', playlistId);
  formData.append('post[playlistitem_scope]', scope);
  console.log(formData);

  fetch('/media_objects/' + moId + '/add_to_playlist', {
    method: 'POST',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': query('meta[name="csrf-token"]').content
    },
    body: formData
  })
    .then(response => response.json())
    .then(res => {
      handleAddSuccess(res);
    })
    .catch(err => {
      handleAddError(err);
    });
}

/** Show success message for add to playlist */
function handleAddSuccess(response) {
  let alertEl = getById('add_to_playlist_alert');
  let messageEl = getById('add_to_playlist_result_message');
  let formGroup = getById('add_to_playlist_form_group');

  if (!alertEl || !messageEl || !formGroup) return;

  alertEl.classList.remove('alert-danger');
  alertEl.classList.add('alert-success');
  messageEl.innerHTML = response.message;
  alertEl.style.display = 'block';

  formGroup.style.display = 'none';
  resetAddToPlaylistForm();
}

/** Show error message for add to playlist */
function handleAddError(error) {
  let alertEl = getById('add_to_playlist_alert');
  let messageEl = getById('add_to_playlist_result_message');
  let formGroup = getById('add_to_playlist_form_group');

  if (!alertEl || !messageEl || !formGroup) return;

  let message = error.statusText || 'There was an error adding to playlist';

  if (error.responseJSON && error.responseJSON.message) {
    message = error.responseJSON.message.join('<br/>');
  }

  alertEl.classList.remove('alert-success');
  alertEl.classList.add('alert-danger', 'add_to_playlist_alert_error');
  alertEl.style.display = 'block';
  messageEl.innerHTML = 'ERROR: ' + message;
  formGroup.style.display = 'none';

  resetAddToPlaylistForm();
}

/** Reset add to playlist form */
function resetAddToPlaylistForm() {
  const description = getById('playlist_item_description');
  const title = getById('playlist_item_title');
  const scopeInput = query('input[name="post[playlistitem_scope]"]');
  const structureRadio = getById('playlistitem_scope_structure');

  if (description) description.value = '';
  if (title) title.value = '';
  if (scopeInput) scopeInput.checked = false;
  if (structureRadio) structureRadio.checked = true;
}

/** Reset add to playlist panel when alert is closed */
function closeAlert() {
  const alertEl = getById('add_to_playlist_alert');
  const formGroup = getById('add_to_playlist_form_group');
  const trackRadio = getById('playlistitem_scope_track');
  const sectionRadio = getById('playlistitem_scope_section');

  if (alertEl) alertEl.style.display = 'none';
  if (formGroup) formGroup.style.display = 'block';

  // Set default selection in options list when alert is closed
  if (trackRadio && trackRadio.disabled) {
    if (sectionRadio) sectionRadio.checked = true;
  } else {
    if (trackRadio) trackRadio.checked = true;
  }
}

/** Refresh stream token by reloading active m3u8 */
function m3u8Reload() {
  player = getById('iiif-media-player');
  fetch(player.player.currentSources()[0]["src"]);
};
