(function() {
    function setActiveSection(activeSegment) {
      $('a.stream').removeClass('current');
      $('#link_'+activeSegment).addClass('current');
    }

    function setActiveLabel(title) {
      target = $('#stream_label');
      if (target) {
        target.html(title);
      }
    }

    /*
     * This method should take care of the heavy lifting involved in passing a message
     * to the player
     */
    function refreshStream(stream, package_id) {
    }

    $(document).ready(function() {
        $('a.stream').click(function(event) {
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
                setActiveSection(data.mediapackage_id);
                refreshStream(data.stream, data.mediapackage_id);
            });
        });
    });
}());