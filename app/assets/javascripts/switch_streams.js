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
        var opts = { flash: stream_info.stream_flash, 
                     hls: stream_info.stream_hls, 
                     poster: stream_info.poster_image,
                     mediaPackageId: stream_info.mediapackage_id };
        if (typeof currentPlayer !== "undefined" && currentPlayer !== null) {
          //debugger;
          currentPlayer.switchStream(opts);
        } else {
          currentPlayer = AvalonPlayer.init($('#player'), opts);
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
