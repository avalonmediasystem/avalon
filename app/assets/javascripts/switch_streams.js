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
      Opencast.Player.doPause();
      Opencast.Player.setCurrentTime('00:00:00');
      Opencast.Player.setPlayhead(0);
      $.getURLParameter = function (name) { 
        if (name == "id") {
          return stream_info.mediapackage_id;
        } else if (name == "mediaUrl1") {
          return stream_info.stream;
        } else if (name == "mimetype1") {
          return stream_info.mimetype;
        } else { 
          return origGetURLParameterFn(name);
        } 
      }
      Opencast.Initialize.initme();
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
