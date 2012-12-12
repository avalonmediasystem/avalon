/**
 * Use an anonymous inner function to scope it from the global namespace.
 * Bad Javascript!
 */
(function() {
    function setActiveSection(activeSegment) {
      $('a[data-segment]').removeClass('current-stream');
      $("a[data-segment='" + activeSegment + "']").addClass('current-stream');
    }

    function setActiveLabel(title) {
      target = $('#stream_label');
      if (target) {
        target.fadeToggle(50, function() { target.text(title); target.fadeToggle(50) });
      }
    }

    /*
     * This method should take care of the heavy lifting involved in passing a message
     * to the player
     */
    function refreshStream(stream_info) {
      var opts = { flash: stream_info.stream_flash, 
                   hls: stream_info.stream_hls, 
                   mimetype: stream_info.mimetype,
                   format: stream_info.format };
      avalonPlayer.switchStream(opts);
    }

    $(document).ready(function() {
        $('a[data-segment]').click(function(event) {
            event.preventDefault();
            var target = $(this);
            /*
             * Do three things to update a stream
             *
             * 1) Replace the H2 container's text with the new section name
             * 2) Set the active stream
             * 3) Refresh the stream by passing a message to the player
             */
            var uri = target.attr('href').split('?')
            $.getJSON(uri[0], uri[1], function(data) {
                setActiveLabel(data.label);
                setActiveSection(target.attr('data-segment'));
                refreshStream(data.stream, data.mediapackage_id);
                refreshStream(data);
            });
        });
    });
}());
