/* 
 * Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

window.AvalonStreams = {
    setActiveSection: function(activeSegment, stream_info) {
      sectionnodes = $("a[data-segment='" + activeSegment + "']");
      if ( sectionnodes.length > 0 ) {
	/* Start by resetting the state of all sections */
	$('a.current-stream ~ i').remove();
	$('a[data-segment]').removeClass('current-stream');
        currentTime = currentPlayer.getCurrentTime()
        if ( typeof(sectionnodes[0].dataset.fragmentbegin) == 'undefined' ) {
	  // section doesn't have mediafragment data
	  $(sectionnodes[0]).addClass('current-stream');
        } else {
	  // find the sub-section that contains the player's current time
          for (i=0; i<sectionnodes.length; i++){
	    if (currentTime >= parseFloat(sectionnodes[i].dataset.fragmentbegin) && 
                 ( i+1 == sectionnodes.length || currentTime < parseFloat(sectionnodes[i+1].dataset.fragmentbegin))){
	      $(sectionnodes[i]).addClass('current-stream');
	      i=sectionnodes.length; //break
	    }
	  }
        }
        $('a.current-stream').trigger('streamswitch', [stream_info]).parent().append(AvalonStreams.nowPlaying);
      }
    },

    /*
     * This method should take care of the heavy lifting involved in passing a message
     * to the player
     */
    refreshStream: function(stream_info) {
      if (stream_info.stream_flash.length > 0) {
        if (typeof currentPlayer !== "undefined" && currentPlayer !== null) {
          currentPlayer.pause();
          var newSrc = [];
          var sources = [];
          var videoNode = $(currentPlayer.domNode);
          videoNode.html("");

          for (var i = 0; i < stream_info.stream_flash.length; i++) {
            var flash = stream_info.stream_flash[i];
            newSrc.push({ src: flash.url, type: 'video/rtmp' });
            videoNode.append('<source src="' + flash.url + '" data-quality="' + flash.quality + '" data-plugin-type="flash" type="video/rtmp">');
          }
          for (var i = 0; i < stream_info.stream_hls.length; i++) {
            var hls = stream_info.stream_hls[i];
            newSrc.push({ src: hls.url, type: 'application/vnd.apple.mpegURL' });
            videoNode.append('<source src="' + hls.url + '" data-quality="' + hls.quality + '" data-plugin-type="native" type="application/vnd.apple.mpegURL">');
          }
          
          if (stream_info.poster_image != "undefined" && stream_info.poster_image != null)
            currentPlayer.setPoster(stream_info.poster_image);
          currentPlayer.buildqualities(currentPlayer, currentPlayer.controls, currentPlayer.layers, currentPlayer.media);
          currentPlayer.media.addEventListener('loadedmetadata', function loadedmetadata () {
            currentPlayer.setCurrentTime(isNaN(parseFloat(stream_info['t']))? 0 : parseFloat(stream_info['t'].split(',')[0]));
            currentPlayer.media.removeEventListener('loadedmetadata', loadedmetadata);
          }, true);
          currentPlayer.load(); 
        }
      }
    },
    
    nowPlaying: '<i class="now-playing fa fa-arrow-circle-right"></i>'
};

$().ready(function() {
    /* Initialize the extra eye candy on page load */
    AvalonStreams.setActiveSection($('a.current-stream').data('segment'), null);
    
    $('a[data-segment]').click(function(event) {
      var target = $(this);
      var segment = target.data('segment');

      // Only does the AJAX switching if type of new stream is identical to old stream,
      // otherwise do the regular page load
      if ($('a.current-stream').data('is-video') == target.data('is-video')) {
	event.preventDefault();

        // If it is the same segment, just change the offset
        if ($('a.current-stream').data('segment') == target.data('segment') && typeof(target.data('fragmentbegin')!='undefined')) {
          currentPlayer.setCurrentTime(parseFloat(target.data('fragmentbegin')));
	} else {

          /**
           * Explicitly make this a JSON request 
           */
	  var uri = target.data('native-url').split('?')[0] + '.json';
	  var params = target.data('native-url').split('?')[1];

	  $.getJSON(uri, 'content=' + segment + '&' + params, function(data) {
	    AvalonStreams.refreshStream(data);
            AvalonStreams.setActiveSection(segment, data);
	  });
	}
      }
    });
});
