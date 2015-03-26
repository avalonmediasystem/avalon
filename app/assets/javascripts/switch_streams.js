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
      /* Start by resetting the state of all sections */
      $('a.current-stream ~ i').remove();
      $('a[data-segment]').removeClass('current-stream');

      jumped = false;
      offset = 0
      if (typeof stream_info != 'undefined' && stream_info !== null && !isNaN(parseFloat(stream_info['t']))) {
	  // the event handler for MediaElement.loadedmetadata will refer to these global values
	  offset = parseFloat(stream_info['t'].split(',')[0]);
      }

      $("a[data-segment='" + activeSegment + "']").each(function(index,node) {
	      if (offset >= parseFloat(node.dataset.fragmentbegin) && offset < parseFloat(node.dataset.fragmentend)){
		  $(node).addClass('current-stream');
	      }
	  });

      $('a.current-stream').trigger('streamswitch', [stream_info]).parent().append(AvalonStreams.nowPlaying);
    },

    setActiveLabel: function(title) {
      target = $('#stream_label');
      if (target) {
	/* This seems a bit unneeded with CSS3 but that can wait for a
	 * future release
	 */
        target.fadeToggle(50, function() { target.text(title); target.fadeToggle(50) });
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
          
          // Rebuilds the quality selector
          //currentPlayer.setSrc(newSrc);
          if (stream_info.poster_image != "undefined" && stream_info.poster_image != null)
            currentPlayer.setPoster(stream_info.poster_image);
          currentPlayer.buildqualities(currentPlayer, currentPlayer.controls, currentPlayer.layers, currentPlayer.media);
          currentPlayer.load(); 
        } else {
          //currentPlayer = AvalonPlayer.init($('#player'), opts);
        }
      }
    },
    
    nowPlaying: '<i class="now-playing fa fa-arrow-circle-right"></i>'
};

$().ready(function() {
    /* Initialize the extra eye candy on page load */
    AvalonStreams.setActiveSection($('a.current-stream').data('segment'), null);
    
    $('a[data-segment]').click(function(event) {

      // Only does the AJAX switching if type of new stream is identical to old stream,
      // otherwise do the regular page load
      if ($('a.current-stream').data('is-video') == $(this).data('is-video')) {
        event.preventDefault();
        var target = $(this);

        /**
         * Explicitly make this a JSON request 
         */
        var uri = target.attr('href').split('?')[0] + '.json';
	var params = target.attr('href').split('?')[1];
        var segment = $(this).data('segment');

        $.getJSON(uri, 'content=' + segment + '&' + params, function(data) {
          AvalonStreams.setActiveSection(segment, data);
          AvalonStreams.refreshStream(data);
        });
      }
    });
});
