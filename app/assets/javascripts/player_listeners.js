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

let canvasIndex = -1;
let currentSectionLabel = undefined;
let addToPlaylistListenersAdded = false;
let searchFieldListenerAdded = false;
let firstLoad = true;
let streamId = '';
let isMobile = false;
let isPlaying = false;
let reloadInterval = false;
let currentTime;

/**
 * Bind action buttons on the page with player events and re-populate details
 * related to the current section (masterfile) for each action form when a new
 * section is loaded into the player.
 * This function is called on 500ms interval and it keeps polling for player events
 * to update action forms and buttons.
 * @param {Object} player 
 * @param {String} mediaObjectId 
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 */
function addActionButtonListeners(player, mediaObjectId, sectionIds, sectionShareInfos) {
  if (player && player.player != undefined) {
    let currentIndex = parseInt(player.dataset.canvasindex);
    /* Ensure we only add player listeners once */
    if (firstLoad === true) {
      /* Add player event listeners to update UI components on the page */
      // Listen to 'seeked' event to udate add to playlist form when using while media is playing or manually seeking
      player.player.on('seeked', () => {
        if (getActiveItem() != undefined) {
          activeTrack = getActiveItem(false);
          if (activeTrack != undefined) {
            streamId = activeTrack.streamId;
          }
          disableEnableCurrentTrack(activeTrack, player.player.currentTime(), isPlaying, currentSectionLabel);
        }
      });

      player.player.on('play', () => { isPlaying = true; });

      player.player.on('pause', () => { isPlaying = false; });

      /*
        Disable action buttons tied to player related information on player's 'emptied' event which functions
        parallel to the player's src changes. So, that the user doesn't interact with them get corrupted data 
        in the UI when player is loading the new section media into it.
        Once the player is fully loaded these buttons are enabled as needed.
      */
      player.player.on('emptied', () => {
        resetAllActionButtons();
      });

      /*
        Enable action buttons on player's 'loadstart' event which functions parallel to the player's src changes.
        Sometimes the player event to disable the buttons is triggered after the function to enable the buttons,
        resulting in the buttons never enabling. Since the enabling of the action buttons occurs before the player
        is emptied, it is also possible that the information populating the buttons is for the old canvas, so we
        run `buildActionButtons` again rather than just enabling the buttons.
      */
      player.player.on('loadstart', () => {
        let addToPlaylistBtn = document.getElementById('addToPlaylistBtn');
        let thumbnailBtn = document.getElementById('thumbnailBtn');
        let timelineBtn = document.getElementById('timelineBtn');

        if (addToPlaylistBtn.disabled || thumbnailBtn.disabled || timelineBtn.disabled) {
          buildActionButtons(player, mediaObjectId, sectionIds, sectionShareInfos);
        }
      });
    }
    /*
      For both Android and iOS, player.readyState() is 0 until media playback is
      started. Therefore, use player.src() to check whether there's a playable media
      loaded into the player instead of player.readyState().
      Keep the player.readyState() >= 2 check for desktop browsers, because without
      that check the add to playlist form populates NaN values for time fields when user
      clicks the 'Add to Playlist' button immediately on page load, which does not 
      happen in mobile context.
    */
    const USER_AGENT = window.navigator.userAgent;
    // Identify both iPad and iPhone devices
    const IS_IPHONE = (/iPhone/i).test(USER_AGENT);
    const IS_MOBILE = (/Mobi/i).test(USER_AGENT);
    const IS_TOUCH_ONLY = navigator.maxTouchPoints && navigator.maxTouchPoints > 2 && !window.matchMedia("(pointer: fine").matches;
    const IS_SAFARI = (/Safari/i).test(USER_AGENT);
    // For mobile devices use this check instead of player.readyState() >= 2 for enabling action buttons
    isMobile = (IS_TOUCH_ONLY || IS_IPHONE || IS_MOBILE) && IS_SAFARI && player?.player.src() != '';
    if (currentIndex != canvasIndex && !player.player.canvasIsEmpty) {
      if (isMobile || player?.player.readyState() >= 2) {
        canvasIndex = currentIndex;
        buildActionButtons(player, mediaObjectId, sectionIds, sectionShareInfos);
        firstLoad = false;
      }
    }
    /* 
      Update only share links when Canvas/section is empty,
      i.e. Canvas/section is empty with an inaccessible media source
    */
    if (currentIndex != canvasIndex && player.player.canvasIsEmpty) {
      canvasIndex = currentIndex;
      setUpShareLinks(mediaObjectId, sectionIds, sectionShareInfos);
      resetAllActionButtons();
    }

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
 * Reset the action buttons and global variables on Canvas/section change
 */
function resetAllActionButtons() {
  currentSectionLabel = undefined;
  let addToPlaylistBtn = document.getElementById('addToPlaylistBtn');
  $('#addToPlaylistPanel').collapse('hide');
  resetAddToPlaylistForm();
  if (addToPlaylistBtn) {
    addToPlaylistBtn.disabled = true;
  }
  let thumbnailBtn = document.getElementById('thumbnailBtn');
  if (thumbnailBtn) {
    thumbnailBtn.disabled = true;
  }
  let timelineBtn = document.getElementById('timelineBtn');
  if (timelineBtn) {
    timelineBtn.disabled = true;
  }
}

/**
 * Build action buttons for create thumbnail, add to playlist, create timeline and share
 * for the current section (masterfile) loaded into the player
 * @param {Object} player player object on page
 * @param {String} mediaObjectId 
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 */
function buildActionButtons(player, mediaObjectId, sectionIds, sectionShareInfos) {
  setUpShareLinks(mediaObjectId, sectionIds, sectionShareInfos);
  setUpAddToPlaylist(player, sectionIds, mediaObjectId);
  setUpCreateThumbnail(player, sectionIds);
  setUpCreateTimeline(player);
}

/**
 * Populate the relevant share links for the current section (masterfile) loaded into
 * the player on page
 * @param {String} mediaObjectId 
 * @param {Array<String>} sectionIds array of ordered masterfile id in the mediaobject
 */
function setUpShareLinks(mediaObjectId, sectionIds, sectionShareInfos) {
  const sectionId = sectionIds[canvasIndex];
  const sectionShareInfo = sectionShareInfos[canvasIndex];
  const { lti_share_link, link_back_url, embed_code } = sectionShareInfo;

  $('#share-link-section').val(link_back_url).attr('placeholder', link_back_url);
  $('#ltilink-section').val(lti_share_link).attr('placeholder', lti_share_link);
  $('#embed-part').val(embed_code);

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
 * Build and setup add to playlist form on section (masterfile) change
 * @param {Object} player 
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 * @param {String} mediaObjectId
 */
function setUpAddToPlaylist(player, sectionIds, mediaObjectId) {
  let addToPlaylistBtn = document.getElementById('addToPlaylistBtn');

  if (addToPlaylistBtn && addToPlaylistBtn.disabled
    && (player.player?.readyState() >= 2 || isMobile)) {
    addToPlaylistBtn.disabled = false;
    if (!addToPlaylistListenersAdded) {
      // Add 'Add new playlist' option to dropdown
      window.add_new_playlist_option();
      addToPlaylistListeners(sectionIds, mediaObjectId);
    }
  }
}

/**
 * Event listeners for HTML elementes associated with add to playlist action
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 * @param {String} mediaObjectId
 */
function addToPlaylistListeners(sectionIds, mediaObjectId) {
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
      isPlaying,
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
      if (activeTrack === undefined) {
        activeTrack = getActiveItem(false);
      }
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

  // Set playlist search box to readonly in mobile browsers to prevent
  // keyboard from popping up when opening playlist dropdown.
  $('.select2-selection').on("click", function () {
    const IS_TOUCH_ONLY = navigator.maxTouchPoints && navigator.maxTouchPoints > 2 && !window.matchMedia("(pointer: fine").matches;
    let searchField = $('.select2-search__field');
    if ((/Mobi|iPhone/i.test(window.navigator.userAgent) || IS_TOUCH_ONLY) && searchField.length > 0) {
      searchField.attr('readonly', 'readonly');
      if (!searchFieldListenerAdded) {
        searchField.on('click', function (e) {
          searchField.removeAttr('readonly').select();
        });

        searchFieldListenerAdded = true;
      }
    }
  });

  addToPlaylistListenersAdded = true;
}

/**
 * Build and setup create thubmnail button for the current section (masterfile)
 * @param {Object} player 
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 */
function setUpCreateThumbnail(player, sectionIds) {
  let thumbnailBtn = document.getElementById('thumbnailBtn');
  let baseUrl = '';
  let offset = '';

  // Leave 'Create Thumbnail' button disabled when item is audio
  if (thumbnailBtn && thumbnailBtn.disabled
    && (player.player?.readyState() >= 2 || isMobile) && !player.player.audioOnlyMode()) {
    thumbnailBtn.disabled = false;

    /*
     Only add the click event handlers for 'Create Thumbnail' and 'Update Poster Image'
     buttons only once (on initial page load). This is to avoid adding the same event 
     handler on each new section load, which results in exponentially growing API requests
     each time the thumbnail is updated.
    */
    if (firstLoad) {
      thumbnailBtn.addEventListener('click',
        () => handleCreateThumbnailModalShow(sectionIds, offset, baseUrl));
      document.getElementById('create-thumbnail-submit-button').addEventListener('click',
        () => handleUpdateThumbnail(sectionIds, offset, baseUrl));
    }
  }
};

/**
 * Event handler for the click event on 'Create Thumbnail' button
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 * @param {String} offset time offset for the selected frame
 * @param {String} baseUrl base URL for the API request to get the still frame
 */
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

/**
 * Event handler for the click event on 'Update Poster Image' button in the modal
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 * @param {String} offset time offset for the selected frame
 * @param {String} baseUrl base URL for the API request to set the thumbnail
 */
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

/**
 * Build and setup create timeline button for the current section (masterfile)
 * @param {Object} player 
 */
function setUpCreateTimeline(player) {
  let timelineBtn = document.getElementById('timelineBtn');

  if (timelineBtn && timelineBtn.disabled
    && (player.player?.readyState() >= 2 || isMobile)) {
    timelineBtn.disabled = false;
    timelineBtn.addEventListener('click',
      () => handleCreateTimelineModalShow()
    );
  }
}

/**
 * Event handler for the click event on 'Create Timeline' button
 */
function handleCreateTimelineModalShow() {
  let title;
  let currentPlayer = document.getElementById('iiif-media-player').player;

  let $modalBody = $('#timelineModal').find('div#new-timeline-inputs')[0];
  let bodyText = "<p>Choose scope for new timeline:</p>";

  title = $('#timelineModal')[0].dataset.title;
  let timelineScopes = getTimelineScopes();
  let scopes = timelineScopes.scopes;
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

/**
 * Handler to refresh stream tokens via reloading the m3u8 file
 */
function initM3U8Reload(player, mediaObjectId, sectionIds, sectionShareInfos) {
  if (player && player.player != undefined) {
    if (firstLoad === true) {
      player.player.on('pause', () => {
        currentTime = player.player.currentTime();
        // How long to wait before resetting stream tokens: default 5 minutes
        intervalLength = 5 * 60 * 1000;
        reloadInterval = setInterval(m3u8Reload, intervalLength);
      });

      player.player.on('play', () => {
        if (reloadInterval !== false) {
          clearInterval(reloadInterval);
          reloadInterval = false;
        }
      });

      player.player.on('waiting', () => {
        m3u8Reload();
      });
    }
  }
}
