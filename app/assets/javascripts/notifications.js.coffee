$(document).ready ->
  notification = $('.flash-messages .notification')
  notification_text = notification.text()
  if notification_text.length > 0
    noty
      layout: "topRight"
      theme: "defaultTheme"
      type: "alert"
      text: notification_text
      timeout: 4000
    notification.empty()
