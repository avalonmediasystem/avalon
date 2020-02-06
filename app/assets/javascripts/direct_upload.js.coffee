$ ->
  $('.directupload').find("input:file").each (i, elem)->
    file_input = $(elem)
    form = $(file_input.parents('form:first'))
    submit_button = form.find('input[type="submit"], *[data-trigger="submit"]')
    submit_button.on 'click', ->
      $('.directupload input:file').fileupload 'send',
        files: $('.directupload input:file').prop('files')
      return false
    progress_bar  = $("<div class='bar'></div>");
    bar_container = $("<div class='progress'></div>").append(progress_bar);
    $('div.fileinput').after(bar_container)
    file_input.fileupload
      fileInput:        file_input
      url:              form.data('url')
      type:             'POST'
      autoUpload:       false
      formData:         form.data('form-data')
      paramName:        'file'
      dataType:         'XML'
      replaceFileInput: false
      progressall: (e, data)->
        progress = parseInt(data.loaded / data.total * 100, 10)
        progress_bar.css('width', "#{progress}%")
      start: (e)->
        submit_button.prop('disabled', true)
        progress_bar.
          css('background', 'green').
          css('display', 'block').
          css('width', '0%').
          text("Loading...")
      done: (e, data)->
        submit_button.prop('disabled', false)
        progress_bar.text("Uploading done")

        # extract key and generate URL from response
        key    = $(data.jqXHR.responseXML).find("Key").text();
        bucket = $(data.jqXHR.responseXML).find("Bucket").text();
        url   = "s3://#{bucket}/#{key}"

        # create hidden field
        input = $ "<input />",
          type:  'hidden'
          name:  'selected_files[0][url]'
          value: url
        file_input.replaceWith(input)
        form.submit()
      fail: (e, data)->
        submit_button.prop('disabled', false)
        progress_bar.
          css("background", "red").
          text("Failed")
