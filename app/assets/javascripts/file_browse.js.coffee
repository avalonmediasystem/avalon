$ ->
  initialized = false
  $('#browse-btn').browseEverything()
    .show ->
      skip_box = $('#web_upload input[name=workflow]').closest('span')
        .clone().removeClass().css('margin-right','10px')
      
      $('.ev-cancel').before skip_box
      $('.ev-providers .ev-container a').click()
      initialized = true
    .done (data) -> 
      if data.length > 0
        $('#dropbox_form input[name=workflow]').val($('#browse-everything input[name=workflow]:checked').val())
        $('#dropbox_form').submit() 
  
  $(document).on 'click', 'a[data-trigger="submit"]', (event) ->
    $(this).closest('form').submit()
