$(document).ready(function() {
    $('a.stream').click(function(event) {
        event.preventDefault();
        var target = $(this);
        $.get("" + document.location.pathname + "?content=" + (target.data('segmentId')), function(data) {
            $('#player').html(data);
            $('#stream_label').html(target.html());
            $('a.stream.current').removeClass('current');
            target.addClass('current');
        });
    });
});