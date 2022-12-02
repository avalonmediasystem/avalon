// Requires moment.js
function localize_times() {
  $('*[data-utc-time]').each(function() {
    $(this).text(moment($(this).data('utc-time')).format('LLL'))
  });
}

$(document).ready(localize_times);
$(document).on('draw.dt', localize_times);
