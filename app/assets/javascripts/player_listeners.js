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
let firstLoad = true;
let reloadAdded = false;
let streamId = '';
let isMobile = false;
let isPlaying = false;
let reloadInterval = false;
let seeking = false;
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
        let addToPlaylistBtn = getById('addToPlaylistBtn');
        let thumbnailBtn = getById('thumbnailBtn');
        let timelineBtn = getById('timelineBtn');

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
      setUpShareLinks(sectionShareInfos);
      resetAllActionButtons();
    }

    // Collapse sub-panel related to the selected option in the add to playlist form when it is collapsed
    let playlistSection = getById('playlistitem_scope_section');
    let playlistTrack = getById('playlistitem_scope_track');
    let multiItemExpandedEl = getById('multiItemCheck.show');
    let moreDetailsExpandedEl = getById('moreDetails.show');
    let multiItemExpanded = multiItemExpandedEl ? multiItemExpandedEl.value : undefined;
    let moreDetailsExpanded = moreDetailsExpandedEl ? moreDetailsExpandedEl.value : undefined;
    if (playlistSection?.checked && multiItemExpanded === undefined && moreDetailsExpanded === undefined) {
      collapseMultiItemCheck();
    } else if (playlistTrack?.checked && multiItemExpanded === undefined && moreDetailsExpanded === undefined) {
      collapseMoreDetails();
    }
  }
}
/**
 * Reset the action buttons and global variables on Canvas/section change
 */
function resetAllActionButtons() {
  currentSectionLabel = undefined;
  let addToPlaylistBtn = getById('addToPlaylistBtn');
  if (getById('addToPlaylistPanel')?.classList.contains('show')) {
    showOrCollapse(getById('addToPlaylistPanel'), false);
  }
  resetAddToPlaylistForm();
  if (addToPlaylistBtn) addToPlaylistBtn.disabled = true;
  let thumbnailBtn = getById('thumbnailBtn');
  if (thumbnailBtn) thumbnailBtn.disabled = true;

  let timelineBtn = getById('timelineBtn');
  if (timelineBtn) timelineBtn.disabled = true;
}

/**
 * Build action buttons for create thumbnail, add to playlist, create timeline and share
 * for the current section (masterfile) loaded into the player
 * @param {Object} player player object on page
 * @param {String} mediaObjectId 
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 */
function buildActionButtons(player, mediaObjectId, sectionIds, sectionShareInfos) {
  setUpShareLinks(sectionShareInfos);
  setUpAddToPlaylist(player, sectionIds, mediaObjectId);
  setUpCreateThumbnail(player, sectionIds);
  setUpCreateTimeline(player);
}

/**
 * Populate the relevant share links for the current section (masterfile) loaded into
 * the player on page
 * @param {Array<Object>} sectionShareInfos
 */
function setUpShareLinks(sectionShareInfos) {
  const sectionShareInfo = sectionShareInfos[canvasIndex];
  const { lti_share_link, link_back_url, embed_code } = sectionShareInfo;

  const shareLinkSection = getById('share-link-section');
  if (shareLinkSection) {
    shareLinkSection.value = link_back_url;
    shareLinkSection.setAttribute('placeholder', link_back_url);
  }

  const ltilinkSection = getById('ltilink-section');
  if (ltilinkSection) {
    ltilinkSection.value = lti_share_link;
    ltilinkSection.setAttribute('placeholder', lti_share_link);
  }

  const embedPart = getById('embed-part');
  if (embedPart) {
    embedPart.value = embed_code;
  }

  shareListeners();
}

/**
 * Event listeners for the share panel and tabs
 */
function shareListeners() {
  // Hide add to playlist panel when share resource panel is opened
  const shareResourcePanel = getById('shareResourcePanel');
  if (shareResourcePanel) {
    shareResourcePanel.addEventListener('show.bs.collapse', function () {
      // Hide add to playlist panel if its showing
      const addToPlaylistPanel = getById('addToPlaylistPanel');
      if (addToPlaylistPanel && addToPlaylistPanel.classList.contains('show')) {
        showOrCollapse(addToPlaylistPanel, false);
      }
    });
  }

  const firstShareTab = query('nav.share-tabs');
  if (firstShareTab && !firstShareTab.classList.contains('active')) {
    firstShareTab.classList.add('active');
    const firstShareLink = query('.share-tabs a');
    if (firstShareLink) {
      firstShareLink.setAttribute('aria-selected', 'true');
    }
    const firstTabPane = query('#share-list .tab-content .tab-pane');
    if (firstTabPane) {
      firstTabPane.classList.add('active');
    }
  }

  const shareTabLinks = queryAll('.share-tabs a');
  shareTabLinks.forEach(link => {
    link.addEventListener('click', function (e) {
      e.preventDefault();
      // Show tab using Bootstrap 5 API
      const tab = new bootstrap.Tab(this);
      tab.show();
      // Update aria-selected attributes
      shareTabLinks.forEach(l => l.setAttribute('aria-selected', 'false'));
      this.setAttribute('aria-selected', 'true');
    });
  });
}

/**
 * Build and setup add to playlist form on section (masterfile) change
 * @param {Object} player 
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 * @param {String} mediaObjectId
 */
function setUpAddToPlaylist(player, sectionIds, mediaObjectId) {
  let addToPlaylistBtn = getById('addToPlaylistBtn');

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
  const addToPlaylistPanel = getById('addToPlaylistPanel');
  if (addToPlaylistPanel) {
    addToPlaylistPanel.addEventListener('show.bs.collapse', function (event) {
      // Hide add to playlist alert on panel show
      const playlistAlert = getById('add_to_playlist_alert');
      if (playlistAlert) {
        playlistAlert.style.display = 'none';
      }

      // Hide share resource panel on add to playlist panel show
      const shareResourcePanel = getById('shareResourcePanel');
      if (shareResourcePanel && shareResourcePanel.classList.contains('show')) {
        showOrCollapse(shareResourcePanel, false);
      }

      let playlistForm = getById('add_to_playlist');
      if (!playlistForm) return;

      // For custom scope set start, end times as current time and media duration respectively
      let start, end, currentTime, duration = 0;
      let currentPlayer = getById('iiif-media-player');
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

          if (trackInfo.length === 0) {
            const playlistScopeSection = getById('playlistitem_scope_section');
            if (playlistScopeSection) playlistScopeSection.checked = true;
          }
        }

        if (trackInfo.length > 0) {
          activeTrack = trackInfo[0];
          let trackName = activeTrack.tags.includes('current-section')
            ? activeTrack.label || streamId
            : `${currentSectionLabel} - ${activeTrack.label || streamId}`;
          const currentTrackName = getById('current-track-name');
          if (currentTrackName) currentTrackName.textContent = trackName;
          if (event.target.id === "addToPlaylistPanel") {
            const playlistScopeTrack = getById('playlistitem_scope_track');
            if (playlistScopeTrack) playlistScopeTrack.checked = true;
          }
          // Update start, end times for custom scope from the active timespan
          start = activeTrack.times.begin;
          end = activeTrack.times.end;
        } else {
          activeTrack = undefined;
        }
      }

      const playlistItemTitle = getById('playlist_item_title');
      disableEnableCurrentTrack(
        activeTrack, currentTime, isPlaying,
        // Preserve user edits for the title when available
        (playlistItemTitle ? playlistItemTitle.value : '') || currentSectionLabel
      );
      const currentSectionName = getById('current-section-name');
      if (currentSectionName) currentSectionName.textContent = currentSectionLabel;
      const playlistItemStart = getById('playlist_item_start');
      if (playlistItemStart) playlistItemStart.value = createTimestamp(start || currentTime, true);
      const playlistItemEnd = getById('playlist_item_end');
      if (playlistItemEnd) playlistItemEnd.value = createTimestamp(duration || end, true);

      // Show add to playlist form on show and reset initially
      const addToPlaylistFormGroup = getById('add_to_playlist_form_group');
      if (addToPlaylistFormGroup) addToPlaylistFormGroup.style.display = 'block';
    });
  }

  const addToPlaylistSave = getById('addToPlaylistSave');
  if (addToPlaylistSave) {
    addToPlaylistSave.addEventListener('click', function (e) {
      e.preventDefault();
      const playlistId = getById('post_playlist_id')?.value;

      const playlistScopeTrack = getById('playlistitem_scope_track');
      const playlistTimeSelection = getById('playlistitem_timeselection');
      const playlistScopeSection = getById('playlistitem_scope_section');
      const playlistScopeItem = getById('playlistitem_scope_item');

      if (playlistScopeTrack?.checked) {
        if (activeTrack === undefined) {
          activeTrack = getActiveItem(false);
        }
        let starttime = createTimestamp(activeTrack.times.begin, true);
        let endtime = createTimestamp(activeTrack.times.end, true);
        addPlaylistItem(playlistId, streamId, starttime, endtime);
      } else if (playlistTimeSelection?.checked) {
        let starttime = getById('playlist_item_start') ? getById('playlist_item_start').value : '';
        let endtime = getById('playlist_item_end') ? getById('playlist_item_end').value : '';
        addPlaylistItem(playlistId, streamId, starttime, endtime);
      } else if (playlistScopeSection?.checked) {
        let multiItemCheck = getById('playlistitem_scope_structure')?.checked || false;
        let scope = multiItemCheck ? 'structure' : 'section';
        addToPlaylist(playlistId, scope, streamId, mediaObjectId);
      } else if (playlistScopeItem?.checked) {
        let multiItemCheck = getById('playlistitem_scope_structure')?.checked || false;
        let scope = multiItemCheck ? 'structure' : 'section';
        addToPlaylist(playlistId, scope, '', mediaObjectId);
      } else {
        handleAddError({ responseJSON: { message: ['Please select a playlist option'] } });
      }
    });
  }

  // In testing, this action did not function properly using `hide.bs.collapse`
  // or `hidden.bs.collapse`. Triggering on click and limiting via if-statement
  // was consistent.
  const addToPlaylistBtn = getById('addToPlaylistBtn');
  if (addToPlaylistBtn) {
    addToPlaylistBtn.addEventListener('click', function () {
      // Only reset the form when the panel is closing to mitigate risk
      // of conflicting actions when populating panel.
      const addToPlaylistPanel = getById('addToPlaylistPanel');
      if (addToPlaylistPanel?.classList.contains('show')) {
        resetAddToPlaylistForm();
      }
    });
  }

  addToPlaylistListenersAdded = true;
}

/**
 * Build and setup create thubmnail button for the current section (masterfile)
 * @param {Object} player 
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 */
function setUpCreateThumbnail(player, sectionIds) {
  let thumbnailBtn = getById('thumbnailBtn');
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
      getById('create-thumbnail-submit-button').addEventListener('click',
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
  let currentPlayer = getById('iiif-media-player');
  let imgPolaroid = getById('img-polaroid');
  offset = currentPlayer.player.currentTime();

  const sectionId = sectionIds[canvasIndex];
  baseUrl = '/master_files/' + sectionId;

  if (imgPolaroid) {
    let src = baseUrl + '/poster?offset=' + offset + '&preview=true';

    // Display a preview of thumbnail to user
    imgPolaroid.setAttribute('src', src);
    imgPolaroid.style.opacity = '0';
    imgPolaroid.style.display = 'block';
    // Fade in effect using CSS transition
    setTimeout(() => {
      imgPolaroid.style.transition = 'opacity 0.6s';
      imgPolaroid.style.opacity = '1';
    }, 10);
  }
};

/**
 * Event handler for the click event on 'Update Poster Image' button in the modal
 * @param {Array<String>} sectionIds array of ordered masterfile ids in the mediaobject
 * @param {String} offset time offset for the selected frame
 * @param {String} baseUrl base URL for the API request to set the thumbnail
 */
function handleUpdateThumbnail(sectionIds, offset, baseUrl) {
  let currentPlayer = getById('iiif-media-player');
  const sectionId = sectionIds[canvasIndex];
  baseUrl = '/master_files/' + sectionId;
  offset = currentPlayer.player.currentTime();

  const modalBody = query('.modal-body');
  const thumbnailModal = getById('thumbnailModal');

  // Put in a loading spinner and disable buttons to prevent double clicks
  if (modalBody) {
    modalBody.classList.add('spinner');
  }

  if (thumbnailModal) {
    const buttons = queryAll('button', thumbnailModal);
    buttons.forEach(btn => btn.disabled = true);
  }

  // Create form data for POST request
  const formData = new FormData();
  formData.append('offset', offset);

  // Get CSRF token for Rails
  const csrfToken = query('meta[name="csrf-token"]')?.getAttribute('content');

  fetch(baseUrl + '/still', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken
    },
    body: formData
  })
    .then(response => {
      if (thumbnailModal) toggleModal(thumbnailModal, false);
    })
    .catch(error => {
      console.log(error);
    })
    .finally(() => {
      if (modalBody) {
        modalBody.classList.remove('spinner');
      }
      if (thumbnailModal) {
        const buttons = queryAll('button', thumbnailModal);
        buttons.forEach(btn => btn.disabled = false);
      }
    });
};

/**
 * Build and setup create timeline button for the current section (masterfile)
 * @param {Object} player 
 */
function setUpCreateTimeline(player) {
  let timelineBtn = getById('timelineBtn');

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
  let currentPlayer = getById('iiif-media-player').player;

  const modalBody = query('div#new-timeline-inputs', getById('timelineModal')) || null;
  let bodyText = "<p>Choose scope for new timeline:</p>";

  title = getById('timelineModal')?.dataset.title || '';
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
    let checked = (index == scopes.length - 1) ? 'checked' : '';
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
  modalBody.innerHTML = bodyText;

  const timelineModalSave = getById('timelineModalSave');
  if (timelineModalSave) {
    timelineModalSave.addEventListener('click', function () {
      let label, t, id;
      const timelineScopeCustom = getById('timelinescope_custom');
      if (timelineScopeCustom?.checked) {
        let pattern = /^(\d+:){0,2}\d+(\.\d+)?$/;
        const customBegin = getById('custombegin');
        const customEnd = getById('customend');
        let beginval = customBegin ? customBegin.value : '';
        let endval = customEnd ? customEnd.value : '';
        if (pattern.test(beginval) && pattern.test(endval)) {
          label = 'custom scope';
          t = 't=' + timeToS(beginval) + ',' + timeToS(endval);
        } else {
          if (customBegin) {
            customBegin.style.color = pattern.test(beginval) ? 'black' : 'red';
          }
          if (customEnd) {
            customEnd.style.color = pattern.test(endval) ? 'black' : 'red';
          }
          return;
        }
      } else {
        let selectedIndex = -1;
        for (let index = 0; index < scopes.length; index++) {
          const timelineScope = getById('timelinescope' + index);
          if (timelineScope?.checked) {
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
      const newTimelineTitle = getById('new-timeline-title');
      if (newTimelineTitle) {
        newTimelineTitle.value = label;
      }
      const newTimelineSource = getById('new-timeline-source');
      if (newTimelineSource) {
        newTimelineSource.value = '/master_files/' + id + '?' + t;
      }
      const newTimelineForm = getById('new-timeline-form');
      if (newTimelineForm) {
        newTimelineForm.submit();
      }
    });
  }
}

/**
 * Handler to refresh stream tokens via reloading the m3u8 file
 */
function initM3U8Reload(player) {
  if (player && player.player != undefined) {
    if (reloadAdded === false) {
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

      player.player.on('seeking', () => {
        seeking = true
      });

      player.player.on('waiting', () => {
        if (seeking === true) {
          seeking = false;
        } else {
          m3u8Reload();
        }
      });

      reloadAdded = true;
    }
  }
}
