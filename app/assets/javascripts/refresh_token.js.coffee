$ ->
  refreshToken = ->
    mount_point = $('body').data('mountpoint')
    token = currentPlayer.sources.context.src.split('?')[1]
    $.get("#{mount_point}authorize.txt?#{token}")
      .done -> console.log("Token refreshed")
      .fail -> console.error("Token refresh failed")

  setInterval(refreshToken, 5*60*1000)
