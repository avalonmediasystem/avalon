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
	    if (null != data.label) {
          AvalonStreams.setActiveLabel(data.label);
	    } else {
	      AvalonStreams.setActiveLabel(target.text());
	    }
	    AvalonStreams.setActiveSection(segment);
            AvalonStreams.refreshStream(data);
        });
    });
});
