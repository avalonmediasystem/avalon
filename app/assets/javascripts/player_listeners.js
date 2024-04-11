/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

let canvasIndex = -1;
let currentSectionLabel = undefined;
let listenersAdded = false;
let playerState = -1;

function addActionButtonListeners(player, mediaObjectId, sectionIds) {
  let addToPlaylistBtn = document.getElementById('addToPlaylistBtn');
  let thumbnailBtn = document.getElementById('thumbnailBtn');
  let timelineBtn = document.getElementById('timelineBtn');
  if (player && player.player != undefined) {
    // When section (masterfile) changes update the relevant information for action buttons
    if (parseInt(player.dataset.canvasindex) != canvasIndex) {
      canvasIndex = parseInt(player.dataset.canvasindex);
      buildActionButtons(player, mediaObjectId, sectionIds);
    }
    if (playerState != player.player.readyState() && player.player.readyState() === 4) {
      playerState = player.player.readyState();
      buildActionButtons(player, mediaObjectId, sectionIds);
    }

    // /*
    //   Browsers on MacOS sometimes miss the 'loadedmetadata' event resulting in a disabled action buttons indefinitely.
    //   This timeout enables the disabled action buttons and attach relevant listeners, when this happens. It checks the 
    //   buttons' states and player status and enables action buttons.
    //   Additional check for player's readyState ensures the button is enabled only when player is ready after the timeout.
    // */
    // setTimeout(() => {
    //   // Leave 'Create Thumbnail' button disabled when item is audio
    //   if (thumbnailBtn && thumbnailBtn.disabled
    //     && player.player?.readyState() === 4 && !player.player.isAudio()) {
    //     setUpCreateThumbnail(player, sectionIds);
    //   }
    //   if (timelineBtn && timelineBtn.disabled && player.player?.readyState() === 4) {
    //     setUpCreateTimeline(player);
    //   }
    //   if (addToPlaylistBtn && addToPlaylistBtn.disabled && player.player?.readyState() === 4) {
    //     setUpAddToPlaylist(player, sectionIds);
    //   }
    // }, 100);

    /* Add player event listeners to update UI components on the page */

    // Listen to 'timeupdate' event to udate add to playlist form when using while media is playing or manually seeking
    player.player.on('timeupdate', () => {
      if (getActiveItem() != undefined) {
        activeTrack = getActiveItem(false);
        if (activeTrack != undefined) {
          streamId = activeTrack.streamId;
        }
        disableEnableCurrentTrack(activeTrack, player.player.currentTime(), true, currentSectionLabel);
      }
    });

    // Listen to 'dispose' event to disable action buttons on canvas change
    player.player.on('dispose', () => {
      currentSectionLabel = undefined;
      $('#addToPlaylistPanel').collapse('hide');
      resetAddToPlaylistForm();
      if (addToPlaylistBtn) {
        addToPlaylistBtn.disabled = true;
      }
      /* 
        Disable 'Create Thumbnail' button on player dispose, so that it can be enabled again or keep disabled on the next section load
        based on the player status.      
      */
      if (thumbnailBtn) {
        thumbnailBtn.disabled = true;
        thumbnailBtn.removeEventListener('click', handleCreateThumbnailModalShow);
        document.getElementById('create-thumbnail-submit-button')
          .removeEventListener('click', handleUpdateThumbnail);
      }
      if (timelineBtn) {
        timelineBtn.disabled = true;
        timelineBtn.removeEventListener('click', handleCreateTimelineModalShow);
      }
    });

    // Collapse sub-panel related to the selected option in the add to playlist form when it is collapsed
    let playlistSection = $('#playlistitem_scope_section');
    let playlistTrack = $('#playlistitem_scope_track');
    let multiItemExpanded = $('#multiItemCheck.show').val();
    let moreDetailsExpanded = $('#moreDetails.show').val();
    if (playlistSection.prop("checked") && multiItemExpanded === undefined && moreDetailsExpanded === undefined) {
      collapseMultiItemCheck();
    } else if (playlistTrack.prop("checked") && multiItemExpanded === undefined && moreDetailsExpanded === undefined) {
      collapseMoreDetails();
    }
  }
}

/**
 * Build action buttons for create thumbnail, add to playlist, create timeline and share
 * for the current section (masterfile) loaded into the player
 * @param {Object} player player object on page
 * @param {String} mediaObjectId 
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 */
function buildActionButtons(player, mediaObjectId, sectionIds) {
  setUpShareLinks(mediaObjectId, sectionIds);
  setUpAddToPlaylist(player, sectionIds);
  setUpCreateThumbnail(player, sectionIds);
  setUpCreateTimeline(player);
}

/**
 * Populate the relevant share links for the current section (masterfile) loaded into
 * the player on page
 * @param {String} mediaObjectId 
 * @param {Array<String>} sectionIds array of ordered masterfile id in the mediaobject
 */
function setUpShareLinks(mediaObjectId, sectionIds) {
  const sectionId = sectionIds[canvasIndex];
  $.ajax({
    url: '/media_objects/' + mediaObjectId + '/section/' + sectionId + '/stream',
    type: 'GET',
    success: function (data) {
      const { lti_share_link, link_back_url, embed_code } = data;
      $('#share-link-section')
        .val(link_back_url)
        .attr('placeholder', link_back_url);
      $('#ltilink-section')
        .val(lti_share_link)
        .attr('placeholder', lti_share_link);
      $('#embed-part').val(embed_code);
    },
    error: function (err) {
      console.log(err);
    }
  });
  shareListeners();
}

/**
 * Event listeners for the share panel and tabs
 */
function shareListeners() {
  // Hide add to playlist panel when share resource panel is collapsed
  $('#shareResourcePanel').on('show.bs.collapse', function (e) {
    $('#addToPlaylistPanel').collapse('hide');
  });

  if (!$('nav.share-tabs').first().hasClass('active')) {
    $('nav.share-tabs').first().toggleClass('active');
    $('.share-tabs a').first().attr('aria-selected', true);
    $('#share-list .tab-content .tab-pane').first().toggleClass('active');
  }

  $('.share-tabs a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
    $('.share-tabs a').attr('aria-selected', false);
    $(this).attr('aria-selected', true);
  });
}

/**
 * 
 * @param {Object} player 
 * @param {Array<String>} sectionIds 
 */
function setUpAddToPlaylist(player, sectionIds) {
  let addToPlaylistBtn = document.getElementById('addToPlaylistBtn');

  if (addToPlaylistBtn && addToPlaylistBtn.disabled
    && player.player?.readyState() === 4) {
    addToPlaylistBtn.disabled = false;
    if (!listenersAdded) {
      // Add 'Add new playlist' option to dropdown
      window.add_new_playlist_option();
      addToPlaylistListeners(sectionIds);
    }
  }
}

function addToPlaylistListeners(sectionIds) {
  $('#addToPlaylistPanel').on('show.bs.collapse', function (e) {
    // Hide add to playlist alert on panel show
    $('#add_to_playlist_alert').slideUp(0);
    // Hide share resource panel on add to playlist panel show
    $('#shareResourcePanel').collapse('hide');

    let playlistForm = $('#add_to_playlist')[0];
    if (!playlistForm) {
      return;
    }

    // For custom scope set start, end times as current time and media duration respectively
    let start, end, currentTime, duration = 0;
    let currentPlayer = document.getElementById('iiif-media-player');
    if (currentPlayer && currentPlayer.player) {
      currentTime = currentPlayer.player.currentTime();
      duration = currentPlayer.player.duration();
    }

    let activeTrack = null;
    let mediaObjectTitle = playlistForm.dataset.title;
    let mediaObjectId = playlistForm.dataset.moid;
    let timelineScopes = getTimelineScopes();
    let scopes = timelineScopes.scopes;
    streamId = timelineScopes.streamId || sectionIds[canvasIndex];
    currentSectionLabel = `${mediaObjectTitle || mediaObjectId} - ${streamId}`;

    // Fill in the current track and section titles and custom scope times
    if (scopes?.length > 0) {
      let sectionInfo = scopes.filter(s => s.tags.includes('current-section'));
      let trackInfo = scopes.filter(s => s.tags.includes('current-track'));

      if (sectionInfo?.length > 0) {
        currentSectionLabel = sectionInfo[0].label || currentSectionLabel;

        if (trackInfo.length === 0 && event?.target.id === "addToPlaylistBtn") {
          $('#playlistitem_scope_section').prop('checked', true);
        }
      }

      if (trackInfo.length > 0) {
        activeTrack = trackInfo[0];
        let trackName = activeTrack.tags.includes('current-section')
          ? activeTrack.label || streamId
          : `${currentSectionLabel} - ${activeTrack.label || streamId}`;
        $('#current-track-name').text(trackName);
        if (event?.target.id === "addToPlaylistBtn") {
          $('#playlistitem_scope_track').prop('checked', true);
        }
        // Update start, end times for custom scope from the active timespan
        start = activeTrack.times.begin;
        end = activeTrack.times.end;
      } else {
        activeTrack = undefined;
      }
    }

    disableEnableCurrentTrack(
      activeTrack,
      currentTime,
      false,
      $('#playlist_item_title').val() || currentSectionLabel // Preserve user edits for the title when available
    );
    $('#current-section-name').text(currentSectionLabel);
    $('#playlist_item_start').val(createTimestamp(start || currentTime, true));
    $('#playlist_item_end').val(createTimestamp(duration || end, true));

    // Show add to playlist form on show and reset initially
    $('#add_to_playlist_form_group').slideDown();
  });

  $('#addToPlaylistSave').on('click', function (e) {
    e.preventDefault();
    let playlistId = $('#post_playlist_id').val();
    if ($('#playlistitem_scope_track')[0].checked) {
      let starttime = createTimestamp(activeTrack.times.begin, true);
      let endtime = createTimestamp(activeTrack.times.end, true);
      addPlaylistItem(playlistId, streamId, starttime, endtime);
    } else if ($('#playlistitem_timeselection')[0].checked) {
      let starttime = $('#playlist_item_start').val();
      let endtime = $('#playlist_item_end').val();
      addPlaylistItem(playlistId, streamId, starttime, endtime);
    } else if ($('#playlistitem_scope_section')[0].checked) {
      let multiItemCheck = $('#playlistitem_scope_structure')[0].checked;
      let scope = multiItemCheck ? 'structure' : 'section';
      addToPlaylist(playlistId, scope, streamId, mediaObjectId);
    } else if ($('#playlistitem_scope_item')[0].checked) {
      let multiItemCheck = $('#playlistitem_scope_structure')[0].checked;
      let scope = multiItemCheck ? 'structure' : 'section';
      addToPlaylist(playlistId, scope, '', mediaObjectId);
    } else {
      handleAddError({ responseJSON: { message: ['Please select a playlist option'] } });
    }
  });

  // In testing, this action did not function properly using `hide.bs.collapse`
  // or `hidden.bs.collapse`. Triggering on click and limiting via if-statement
  // was consistent.
  $('#addToPlaylistBtn').on('click', function (e) {
    // Only reset the form when the panel is closing to mitigate risk
    // of conflicting actions when populating panel.
    if ($('#addToPlaylistPanel.show').length > 0) {
      resetAddToPlaylistForm();
    }
  });

  listenersAdded = true;
}

function setUpCreateThumbnail(player, sectionIds) {
  let thumbnailBtn = document.getElementById('thumbnailBtn');
  let baseUrl = '';
  let offset = '';

  // Leave 'Create Thumbnail' button disabled when item is audio
  if (thumbnailBtn && thumbnailBtn.disabled
    && player.player?.readyState() === 4 && !player.player.isAudio()) {
    thumbnailBtn.disabled = false;

    // Add click handlers for the create thumbnail and submit buttons
    document.getElementById('thumbnailBtn').addEventListener('click',
      () => handleCreateThumbnailModalShow(sectionIds, offset, baseUrl));
    document.getElementById('create-thumbnail-submit-button').addEventListener('click',
      () => handleUpdateThumbnail(sectionIds, offset, baseUrl));
  }
};

function handleCreateThumbnailModalShow(sectionIds, offset, baseUrl) {
  let currentPlayer = document.getElementById('iiif-media-player');
  let $imgPolaroid = document.getElementById('img-polaroid');
  offset = currentPlayer.player.currentTime();

  const sectionId = sectionIds[canvasIndex];
  baseUrl = '/master_files/' + sectionId;

  if ($imgPolaroid) {
    let src = baseUrl + '/poster?offset=' + offset + '&preview=true';

    // Display a preview of thumbnail to user
    $imgPolaroid.setAttribute('src', src);
    $($imgPolaroid).fadeIn('slow');
  }
};

function handleUpdateThumbnail(sectionIds, offset, baseUrl) {
  let currentPlayer = document.getElementById('iiif-media-player');
  const sectionId = sectionIds[canvasIndex];
  baseUrl = '/master_files/' + sectionId;
  offset = currentPlayer.player.currentTime();

  const modalBody = document.getElementsByClassName('modal-body')[0];
  // Put in a loading spinner and disable buttons to prevent double clicks
  modalBody.classList.add('spinner');
  $('#thumbnailModal')
    .find('button')
    .attr({ disabled: true });

  $.ajax({
    url: baseUrl + '/still',
    type: 'POST',
    data: {
      offset: offset
    }
  })
    .done(response => {
      $('#thumbnailModal').modal('hide');
    })
    .fail(error => {
      console.log(error);
    })
    .always(() => {
      modalBody.classList.remove('spinner');
      $('#thumbnailModal')
        .find('button')
        .attr({ disabled: false });
    });
};

function setUpCreateTimeline(player) {
  let timelineBtn = document.getElementById('timelineBtn');

  if (timelineBtn && timelineBtn.disabled && player.player?.readyState() === 4) {
    timelineBtn.disabled = false;
    timelineBtn.addEventListener('click', handleCreateTimelineModalShow(player.player));
  }
}

function handleCreateTimelineModalShow(currentPlayer) {
  let scopes = [];
  let title, streamId;

  let $modalBody = $('#timelineModal').find('div#new-timeline-inputs')[0];
  let bodyText = "<p>Choose scope for new timeline:</p>";

  title = $('#timelineModal')[0].dataset.title;
  let timelineScopes = getTimelineScopes();
  scopes = timelineScopes.scopes;
  streamId = timelineScopes.streamId;

  for (let index = 0; index < scopes.length; index++) {
    let scope = scopes[index];
    let label = scope.label;
    // Add mediaobject title for the option representing the current section
    if (scope.tags.includes('current-section')) {
      label = `${title} - ${label}`;
    }
    if (scope.tracks > 1) {
      label += " (" + scope.tracks + " tracks)";
    }
    checked = (index == scopes.length - 1) ? 'checked' : '';
    bodyText += "<div class=\"form-check\">";
    bodyText += "<input class=\"form-check-input\" type=\"radio\" name=\"scope\" id=\"timelinescope" + index + "\" " + checked + ">";
    bodyText += "<label class=\"form-check-label\" for=\"timelinescope" + index + "\" style=\"margin-left: 5px;\"> " + label + "</label>";
    bodyText += "</div>";
  }
  bodyText += "<div class=\"form-check\">";
  bodyText += "<input class=\"form-check-input\" type=\"radio\" name=\"scope\" id=\"timelinescope_custom\" data-id=\"" + streamId + "\">";
  bodyText += "<label class=\"form-check-label\" for=\"timelinescope_custom\" style=\"margin-left: 5px; margin-right: 5px\"> Custom</label>";
  bodyText += "<input type=\"text\" name=\"custombegin\" id=\"custombegin\" size=\"10\" value=\"" + createTimestamp(currentPlayer.currentTime(), true) + "\" \> to ";
  bodyText += "<input type=\"text\" name=\"customend\" id=\"customend\" size=\"10\" value=\"" + createTimestamp(currentPlayer.duration(), true) + "\" \>";
  bodyText += "</div>";
  $modalBody.innerHTML = bodyText;


  $('#timelineModalSave').on('click', function (e) {
    let label, t, id;
    if ($('#timelinescope_custom')[0].checked) {
      let pattern = /^(\d+:){0,2}\d+(\.\d+)?$/;
      let beginval = $('#custombegin')[0].value;
      let endval = $('#customend')[0].value;
      if (pattern.test(beginval) && pattern.test(endval)) {
        label = 'custom scope';
        t = 't=' + timeToS($('#custombegin')[0].value) + ',' + timeToS($('#customend')[0].value);
      } else {
        $('#custombegin').css('color', (pattern.test(beginval) ? 'black' : 'red'));
        $('#customend').css('color', (pattern.test(endval) ? 'black' : 'red'));
        return;
      }
    } else {
      let selectedIndex = -1;
      for (let index = 0; index < scopes.length; index++) {
        if ($('#timelinescope' + index)[0].checked) {
          selectedIndex = index;
          break;
        }
      }
      if (selectedIndex === -1) return;
      let scope = scopes[selectedIndex];
      label = scope.label;
      let { begin, end } = scope.times;
      t = `t=${begin},${end}`;
    }
    id = streamId;
    $('#new-timeline-title')[0].value = label;
    $('#new-timeline-source')[0].value = '/master_files/' + id + '?' + t;
    $('#new-timeline-form')[0].submit();
  });
}
