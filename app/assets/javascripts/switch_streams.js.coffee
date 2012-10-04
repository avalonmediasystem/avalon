$(document).ready ->
  $('a.stream').click (event) ->
    event.preventDefault();
    target = $(this)
    $.get "#{document.location.pathname}?content=#{target.data('segmentId')}", (data) ->
      $('#player').html data
      $('#stream_label').html target.html()
      $('a.stream.current').removeClass 'current'
      target.addClass 'current'
