function setActiveSection(activeSegment) {
  $('a.stream.current').removeClass('current');
  $(activeSegment).addClass('current');
}

function setActiveTitle(title) {
  target = $('#stream_label');
  if (target) {
    target.text = title;
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
        $.get("" + document.location.pathname + "?content=" + (target.data('segmentId')), function(data) {
            setActiveLabel(data('title'));
            setActiveSection(data('segmentId'));
            refreshStream(data('stream'), data('package_id'));
        });
    });
});