// Copyright 2011-2022, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.


/**
 * Get new timeline scopes for active section playing
 * @function getTimelineScopes
 * @param title title of the mediaobject
 * @return { [{string, int, string}], string } { [{label, tracks, t}], streamId } = [scope label, number of tracks, mediafragment], masterfile id
 */
function getTimelineScopes(title) {
  let scopes = new Array();
  let trackCount = 1;
  let currentPlayer = document.getElementById('iiif-media-player');
  let duration = currentPlayer.player.duration();
  let currentStructureItem = $('li[class="ramp--structured-nav__list-item active"]');
  
  let item = currentStructureItem[0].childNodes[1]
  let label = item.text;
  let times = item.hash.split('#t=').reverse()[0];
  let begin = parseFloat(times.split(',')[0]) || 0;
  let end = parseFloat(times.split(',')[1]) || duration;
  let streamId = item.pathname.split('/').reverse()[0];
  scopes.push({
    label: label,
    tracks: trackCount,
    t: `t=${begin},${end}`,
  });

  let parent = currentStructureItem.closest('ul').closest('li');
  while (parent.length > 0) {
    let next = parent.closest('ul').closest('li');
    let tracks = parent.find('li a');
    trackCount = tracks.length;
    begin = parseFloat(tracks[0].hash.split('#t=').reverse()[0].split(',')[0]) || 0;
    end = parseFloat(tracks[trackCount - 1].hash.split('#t=').reverse()[0].split(',')[1]) || '';
    streamId = tracks[0].pathname.split('/').reverse()[0];
    label = parent[0].childNodes[0].textContent;
    scopes.push({
      label: next.length == 0 ? `${title} - ${label}` : label,
      tracks: trackCount,
      t: `t=${begin},${end}`,
    });
    parent = next;
  }
  return { scopes: scopes.reverse(), streamId };
}

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
