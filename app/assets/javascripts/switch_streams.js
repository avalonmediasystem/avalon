/* 
 * Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
    setActiveSection: function(activeSegment) {
      /* Start by resetting the state of all sections */
      $('a.current-stream ~ i').remove();
      $('a[data-segment]').removeClass('current-stream');

      $("a[data-segment='" + activeSegment + "']").addClass('current-stream');
      $('a.current-stream').trigger('streamswitch').parent().append(AvalonStreams.nowPlaying);
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
          currentPlayer.setPoster(stream_info.poster_image);
          currentPlayer.buildqualities(currentPlayer, currentPlayer.controls, currentPlayer.layers, currentPlayer.media);
          //currentPlayer.load(); 
        } else {
          //currentPlayer = AvalonPlayer.init($('#player'), opts);
        }
      }
    },
    
    nowPlaying: '<i class="icon-circle-arrow-left"></i>'
};

$().ready(function() {
    /* Initialize the extra eye candy on page load */
    AvalonStreams.setActiveSection($('a.current-stream').data('segment'));
    
    $('a[data-segment]').click(function(event) {
        event.preventDefault();
        var target = $(this);

        /**
         * Explicitly make this a JSON request 
         */
        var uri = target.attr('href').split('?')[0] + '.json';
        var segment = $(this).data('segment');
        
        $.getJSON(uri, 'content=' + segment, function(data) {
	      AvalonStreams.setActiveSection(segment);
          AvalonStreams.refreshStream(data);
        });
    });
});
