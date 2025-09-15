// Copyright 2011-2025, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.

// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.
// ---  END LICENSE_HEADER BLOCK  ---

$(() => $('.directupload').find("input:file").each(function(i, elem){
  const file_input = $(elem);
  const form = $(file_input.parents('form:first'));
  const submit_button = form.find('input[type="submit"], *[data-trigger="submit"]');
  submit_button.on('click', function() {
    form.addClass('form-disabled');
    $('.directupload input:file').fileupload('send',
      {files: $('.directupload input:file').prop('files')});
    return false;
  });
  const progress_bar  = $("<div class='bar'></div>");
  const bar_container = $("<div class='progress'></div>").append(progress_bar);
  $('div.fileinput').after(bar_container);
  return file_input.fileupload({
    fileInput:        file_input,
    url:              form.data('url'),
    type:             'POST',
    autoUpload:       false,
    formData:         form.data('form-data'),
    paramName:        'file',
    dataType:         'XML',
    replaceFileInput: false,
    progressall(e, data){
      const progress = parseInt((data.loaded / data.total) * 100, 10);
      return progress_bar.css('width', `${progress}%`);
    },
    start(e){
      return progress_bar.
        css('background', 'green').
        css('display', 'block').
        css('width', '0%').
        css('padding', '7px').
        text("Loading...");
    },
    done(e, data){
      form.removeClass('form-disabled');
      progress_bar.text("Uploading done");

      // extract key and generate URL from response
      const key    = $(data.jqXHR.responseXML).find("Key").text();
      const bucket = $(data.jqXHR.responseXML).find("Bucket").text();
      const url   = `s3://${bucket}/${key}`;

      // create hidden field
      const input = $("<input />", {
        type:  'hidden',
        name:  'selected_files[0][url]',
        value: url
      }
      );
      file_input.replaceWith(input);
      return form.submit();
    },
    fail(e, data){
      form.removeClass('form-disabled');
      return progress_bar.
        css("background", "red").
        text("Failed");
    }
  });
}));
