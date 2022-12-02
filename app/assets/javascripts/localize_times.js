// Requires moment.js
$(document).ready(function () {
  $('*[data-utc-time]').each(function() {
    $(this).text(moment($(this).data('utc-time')).format('LLL'))
  });
});
