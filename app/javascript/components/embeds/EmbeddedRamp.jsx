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

import React from 'react';
import {
	IIIFPlayer,
	MediaPlayer
} from '@samvera/ramp';
import 'video.js/dist/video-js.css';
import "@samvera/ramp/dist/ramp.css";
import './Ramp.scss';

const Ramp = ({
	urls,
	media_object_id,
  is_video
}) => {
	const [manifestUrl, setManifestUrl] = React.useState('');
	const [startCanvasId, setStartCanvasId] = React.useState();
  const [startCanvasTime, setStartCanvasTime] = React.useState();
  let interval;

  React.useEffect(() => {
    const { base_url, fullpath_url } = urls;
    // Split the current path from the time fragment in the format .../:id?t=time
    let [fullpath, start_time] = fullpath_url.split('?t=');
    // Split the current path in the format /master_files/:mf_id/embed
    let [_, __, mf_id, ___] = fullpath.split('/');
    // Build the manifest URL
    let url = `${base_url}/media_objects/${media_object_id}/manifest.json`;

    // Set start Canvas ID and start time in the state for Ramp
    setStartCanvasId(
      mf_id && mf_id != undefined
        ? `${base_url}/media_objects/${media_object_id}/manifest/canvas/${mf_id}`
        : undefined
    );
    setStartCanvasTime(
      start_time && start_time != undefined
        ? parseFloat(start_time)
        : undefined
    );
    setManifestUrl(url);

    interval = setInterval(addControls, 500);

    // Clear interval upon component unmounting
    return () => clearInterval(interval);
  }, []);

  const addControls = () => {
    let player = document.getElementById('iiif-media-player');
    if (player && player.player) {
      let embeddedPlayer = player.player

      // Player API handling
      window.addEventListener('message', function(event) {
        var command = event.data.command;

        if (command=='play') embeddedPlayer.play();
        else if (command=='pause') embeddedPlayer.pause();
        else if (command=='toggle_loop') {
          embeddedPlayer.loop() ? embeddedPlayer.loop(false): embeddedPlayer.loop(true);
          embeddedPlayer.autoplay() ? embeddedPlayer.autoplay(false) : embeddedPlayer.autoplay(true);
        }
        else if (command=='set_offset') embeddedPlayer.currentTime(event.data.offset); // time is in seconds
        else if (command=='get_offset') event.source.postMessage({'command': 'currentTime','currentTime': embeddedPlayer.currentTime()}, event.origin);
      });

      if (embeddedPlayer.audioOnlyMode()) { 
        /* 
          Quality selector extends outside iframe for audio items, so we need to disable that control
          and rely on the quality automatically selected by the user's system.
         */
        embeddedPlayer.controlBar.qualitySelector.dispose();
      }

      // Create button component for "View in Repository" and add to control bar
      let repositoryUrl = Object.values(urls).join('/').replace('/embed', '');
      let position = embeddedPlayer.audioOnlyMode() ? embeddedPlayer.controlBar.children_.length : embeddedPlayer.controlBar.children_.length - 1;
      var viewInRepoButton = embeddedPlayer.controlBar.addChild('button', {
        clickHandler: function(event) {
          window.open(repositoryUrl, '_blank').focus();
        }
      }, position);

      viewInRepoButton.addClass('vjs-custom-external-link');
      viewInRepoButton.el_.setAttribute('style', 'cursor: pointer;');
      viewInRepoButton.controlText('View in Repository');

      // Add button icon
      document.querySelector('.vjs-custom-external-link').innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" height="1em" viewBox="0 0 512 512"><!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2023 Fonticons, Inc. --><style>svg{fill:#ffffff}</style><path d="M320 0c-17.7 0-32 14.3-32 32s14.3 32 32 32h82.7L201.4 265.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L448 109.3V192c0 17.7 14.3 32 32 32s32-14.3 32-32V32c0-17.7-14.3-32-32-32H320zM80 32C35.8 32 0 67.8 0 112V432c0 44.2 35.8 80 80 80H400c44.2 0 80-35.8 80-80V320c0-17.7-14.3-32-32-32s-32 14.3-32 32V432c0 8.8-7.2 16-16 16H80c-8.8 0-16-7.2-16-16V112c0-8.8 7.2-16 16-16H192c17.7 0 32-14.3 32-32s-14.3-32-32-32H80z"/></svg>'

      // This function only needs to run once, so we clear the interval here
      clearInterval(interval);
    }  
  };

  return (
  	<IIIFPlayer manifestUrl={manifestUrl}
      customErrorMessage='This embed encountered an error. Please refresh or contact an administrator.'
      startCanvasId={startCanvasId}
      startCanvasTime={startCanvasTime}>
      <MediaPlayer enableFileDownload={false} enablePlaybackRate={is_video} />
    </IIIFPlayer>
  );
};

export default Ramp;
