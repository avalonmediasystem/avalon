$ ->
  if $('.migration_report').length > 0
    refresh = ->
      if $('#live-update').is(':checked')
        $.get document.location.href
        .done (data) ->
          $('.migration_report').html(data)
          setTimeout(refresh, 5000)
    setTimeout(refresh, 5000)
    $('#live-update').change -> refresh()
